# For each opening emphasis-like marker find a matching closing one
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class BalancePairs

      #------------------------------------------------------------------------------
      def self.link_pairs(state)
        delimiters = state.delimiters
        max = state.delimiters.length

        0.upto(max - 1) do |i|
          lastDelim = delimiters[i]

          next if !lastDelim[:close]

          j = i - lastDelim[:jump] - 1

          while j >= 0
            currDelim = delimiters[j]

            if currDelim[:open] &&
               currDelim[:marker] == lastDelim[:marker] &&
               currDelim[:end] < 0 &&
               currDelim[:level] == lastDelim[:level]

              odd_match = false

              # typeofs are for backward compatibility with plugins
              # not needed:  typeof currDelim.length !== 'undefined' &&
              #              typeof lastDelim.length !== 'undefined' &&
              if (currDelim[:close] || lastDelim[:open])
                # from spec:
                # sum of the lengths [...] must not be a multiple of 3
                # unless both lengths are multiples of 3
                if ((currDelim[:length] + lastDelim[:length]) % 3) == 0
                  if (currDelim[:length] % 3 != 0 || lastDelim[:length] % 3 != 0)
                    odd_match = true
                  end
                end
              end

              if !odd_match
                lastDelim[:jump] = i - j
                lastDelim[:open] = false
                currDelim[:end]  = i
                currDelim[:jump] = 0
                break
              end
            end

            j -= currDelim[:jump] + 1
          end
        end
      end
    end
  end
end
