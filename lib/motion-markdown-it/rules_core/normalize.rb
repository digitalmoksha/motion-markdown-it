# Normalize input string
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Normalize

      TABS_SCAN_RE = /[\n\t]/
      NEWLINES_RE  = /\r[\n\u0085]|[\u2424\u2028\u0085]/
      NULL_RE      = /\u0000/


      #------------------------------------------------------------------------------
      def self.inline(state)
        # Normalize newlines
        str = state.src.gsub(NEWLINES_RE, "\n")

        # Replace NULL characters
        str = str.gsub(NULL_RE, '\uFFFD')

        # Replace tabs with proper number of spaces (1..4)
        if str.include?("\t")
          lineStart  = 0
          lastTabPos = 0

          str = str.gsub(TABS_SCAN_RE) do
            md      = Regexp.last_match
            match   = md.to_s
            offset  = md.begin(0)
            if str.charCodeAt(offset) == 0x0A
              lineStart   = offset + 1
              lastTabPos  = 0
              next match
            end
            result      = '    '.slice_to_end((offset - lineStart - lastTabPos) % 4)
            lastTabPos  = offset - lineStart + 1
            result
          end
        end

        state.src = str
      end
    end
  end
end