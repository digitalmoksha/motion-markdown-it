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

        while (pos < max && charCodeAt(state.src, pos) == 0x60)  # `
          pos += 1
        end

        marker = state.src.slice(start...pos)

        matchStart = matchEnd = pos

        while ((matchStart = state.src.index('`', matchEnd)) != nil)
          matchEnd = matchStart + 1

          while (matchEnd < max && charCodeAt(state.src, matchEnd) == 0x60) # `
            matchEnd += 1
          end

          if (matchEnd - matchStart == marker.length)
            if (!silent)
              token         = state.push('code_inline', 'code', 0)
              token.markup  = marker
              token.content = state.src.slice(pos...matchStart).gsub(/[ \n]+/, ' ').strip
            end
            state.pos = matchEnd
            return true
          end
        end

        state.pending += marker if (!silent)
        state.pos     += marker.length
        return true
      end

    end
  end
end
