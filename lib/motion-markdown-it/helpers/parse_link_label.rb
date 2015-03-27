# Parse link label
#
# this function assumes that first character ("[") already matches;
# returns the end of the label
#
#------------------------------------------------------------------------------
module MarkdownIt
  module Helpers
    module ParseLinkLabel
      def parseLinkLabel(state, start, disableNested = false)
        labelEnd  = -1
        max       = state.posMax
        oldPos    = state.pos
        state.pos = start + 1
        level     = 1

        while (state.pos < max)
          marker = state.src.charCodeAt(state.pos)
          if (marker == 0x5D) # ]
            level -= 1
            if (level == 0)
              found = true
              break
            end
          end

          prevPos = state.pos
          state.md.inline.skipToken(state)
          if (marker == 0x5B) # [
            if (prevPos == state.pos - 1)
              # increase level if we find text `[`, which is not a part of any token
              level += 1
            elsif (disableNested)
              state.pos = oldPos
              return -1
            end
          end
        end

        if (found)
          labelEnd = state.pos
        end

        # restore old state
        state.pos = oldPos

        return labelEnd
      end
    end
  end
end