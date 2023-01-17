# Parse backticks
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Backticks
      extend Common::Utils

      #------------------------------------------------------------------------------
      def self.backtick(state, silent)
        pos = state.pos
        ch = charCodeAt(state.src, pos)

        return false if (ch != 0x60)  #  `

        start = pos
        pos  += 1
        max  = state.posMax

        # scan marker length
        while (pos < max && charCodeAt(state.src, pos) == 0x60)  # `
          pos += 1
        end

        marker = state.src.slice(start...pos)
        openerLength = marker.length
      
        if (state.backticksScanned && (state.backticks[openerLength] || 0) <= start)
          state.pending += marker if (!silent)
          state.pos += openerLength
          return true
        end

        matchStart = matchEnd = pos

        # Nothing found in the cache, scan until the end of the line (or until marker is found)
        while ((matchStart = state.src.index('`', matchEnd)) != nil)
          matchEnd = matchStart + 1

          # scan marker length
          while (matchEnd < max && charCodeAt(state.src, matchEnd) == 0x60) # `
            matchEnd += 1
          end

          closerLength = matchEnd - matchStart

          if (closerLength == openerLength)
            # Found matching closer length.
            if (!silent)
              token         = state.push('code_inline', 'code', 0)
              token.markup  = marker
              token.content = state.src.slice(pos...matchStart)
                .gsub(/\n/, ' ')
                .gsub(/^ (.+) $/, '\1')
            end
            state.pos = matchEnd
            return true
          end

          # Some different length found, put it in cache as upper limit of where closer can be found
          state.backticks[closerLength] = matchStart
        end

        # Scanned through the end, didn't find anything
        state.backticksScanned = true

        state.pending += marker if (!silent)
        state.pos     += openerLength
        return true
      end
    end
  end
end
