# Parse link destination
#------------------------------------------------------------------------------
module MarkdownIt
  module Helpers
    module ParseLinkDestination
      include Common::Utils

      #------------------------------------------------------------------------------
      def parseLinkDestination(str, pos, max)
        lines = 0
        start = pos
        result = {ok: false, pos: 0, lines: 0, str: ''}

        if (charCodeAt(str, pos) == 0x3C ) # <
          pos += 1
          while (pos < max)
            code = charCodeAt(str, pos)
            return result if (code == 0x0A) # \n
            return result if (code == 0x3C) # <
            if (code == 0x3E) #  >
              result[:pos] = pos + 1
              result[:str] = unescapeAll(str.slice((start + 1)...pos))
              result[:ok]  = true
              return result
            end
            if (code == 0x5C && pos + 1 < max)  # \
              pos += 2
              next
            end

            pos += 1
          end

          # no closing '>'
          return result
        end

        # this should be ... } else { ... branch

        level = 0
        while (pos < max)
          code = charCodeAt(str, pos)

          break if (code == 0x20)

          # ascii control characters
          break if (code < 0x20 || code == 0x7F)

          if (code == 0x5C && pos + 1 < max) # \
            break if (charCodeAt(str, pos + 1) == 0x20)
            pos += 2
            next
          end

          if (code == 0x28) # (
            level += 1
            return result if (level > 32)
          end

          if (code == 0x29) # )
            break if (level == 0)
            level -= 1
          end

          pos += 1
        end

        return result if start == pos
        return result if level != 0

        result[:str]   = unescapeAll(str.slice(start...pos))
        result[:lines] = lines
        result[:pos]   = pos
        result[:ok]    = true
        return result
      end
    end
  end
end
