# Parse link title
#------------------------------------------------------------------------------
module MarkdownIt
  module Helpers
    module ParseLinkTitle

      #------------------------------------------------------------------------------
      def parseLinkTitle(str, pos, max)
        lines = 0
        start = pos
        result = {ok: false, pos: 0, lines: 0, str: ''}

        return result if (pos >= max)

        marker = str.charCodeAt(pos)

        return result if (marker != 0x22 && marker != 0x27 && marker != 0x28) # " ' (

        pos += 1

        # if opening marker is "(", switch it to closing marker ")"
        marker = 0x29 if (marker == 0x28)

        while (pos < max)
          code = str.charCodeAt(pos)
          if (code == marker)
            result[:pos]   = pos + 1
            result[:lines] = lines
            result[:str]   = unescapeAll(str.slice((start + 1)...pos))
            result[:ok]    = true
            return result
          elsif (code == 0x0A)
            lines += 1
          elsif (code == 0x5C && pos + 1 < max) # \
            pos += 1
            if (str.charCodeAt(pos) == 0x0A)
              lines += 1
            end
          end

          pos += 1
        end

        return result
      end
    end
  end
end