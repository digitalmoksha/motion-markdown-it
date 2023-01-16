# For each opening emphasis-like marker find a matching closing one
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class BalancePairs

      #------------------------------------------------------------------------------
      def self.processDelimiters(state, delimiters)
        openersBottom = {}
        max = delimiters.length
        
        0.upto(max - 1) do |closerIdx|
          closer = delimiters[closerIdx]
      
          # Length is only used for emphasis-specific "rule of 3",
          # if it's not defined (in strikethrough or 3rd party plugins),
          # we can default it to 0 to disable those checks.
          #
          closer[:length] = closer[:length] || 0
      
          next if (!closer[:close])
      
          # Previously calculated lower bounds (previous fails)
          # for each marker and each delimiter length modulo 3.
          unless openersBottom[closer[:marker]]
            openersBottom[closer[:marker]] = [ -1, -1, -1 ]
          end
      
          minOpenerIdx = openersBottom[closer[:marker]][closer[:length] % 3]
          newMinOpenerIdx = -1
      
          openerIdx = closerIdx - closer[:jump] - 1
      
          while openerIdx > minOpenerIdx
            opener = delimiters[openerIdx]
      
            (openerIdx -= opener[:jump] + 1) && next if (opener[:marker] != closer[:marker])
      
            newMinOpenerIdx = openerIdx if (newMinOpenerIdx == -1)
      
            if (opener[:open] && opener[:end] < 0)
      
              isOddMatch = false
      
              # from spec:
              #
              # If one of the delimiters can both open and close emphasis, then the
              # sum of the lengths of the delimiter runs containing the opening and
              # closing delimiters must not be a multiple of 3 unless both lengths
              # are multiples of 3.
              #
              if (opener[:close] || closer[:open])
                if ((opener[:length] + closer[:length]) % 3 == 0)
                  if (opener[:length] % 3 != 0 || closer[:length] % 3 != 0)
                    isOddMatch = true
                  end
                end
              end
      
              if (!isOddMatch)
                # If previous delimiter cannot be an opener, we can safely skip
                # the entire sequence in future checks. This is required to make
                # sure algorithm has linear complexity (see *_*_*_*_*_... case).
                #
                lastJump = openerIdx > 0 && !delimiters[openerIdx - 1][:open] ?
                  delimiters[openerIdx - 1][:jump] + 1 : 0
      
                closer[:jump]  = closerIdx - openerIdx + lastJump
                closer[:open]  = false
                opener[:end]   = closerIdx
                opener[:jump]  = lastJump
                opener[:close] = false
                newMinOpenerIdx = -1
                break
              end
            end
            
            openerIdx -= opener[:jump] + 1
          end
      
          if (newMinOpenerIdx != -1)
            # If match for this delimiter run failed, we want to set lower bound for
            # future lookups. This is required to make sure algorithm has linear
            # complexity.
            #
            # See details here:
            # https://github.com/commonmark/cmark/issues/178#issuecomment-270417442
            #
            openersBottom[closer[:marker]][(closer[:length] || 0) % 3] = newMinOpenerIdx
          end
        end
      end

      #------------------------------------------------------------------------------
      def self.link_pairs(state)
        tokens_meta = state.tokens_meta
        max = state.tokens_meta.length

        processDelimiters(state, state.delimiters)
      
        0.upto(max - 1) do |curr|
          if (tokens_meta[curr] && tokens_meta[curr][:delimiters])
            processDelimiters(state, tokens_meta[curr][:delimiters])
          end
        end
      end
    end
  end
end
