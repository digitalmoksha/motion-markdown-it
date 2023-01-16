# Clean up tokens after emphasis and strikethrough postprocessing:
# Merge adjacent text nodes into one, and re-calculate all token levels
#
# This is necessary because initially emphasis delimiter markers (*, _, ~)
# are treated as their own separate text tokens. Then emphasis rule either
# leaves them as text (needed to merge with adjacent text) or turns them
# into opening/closing tags (which messes up levels inside).
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class TextCollapse

      #------------------------------------------------------------------------------
      def self.text_collapse(state)
        level   = 0
        tokens  = state.tokens
        max     = state.tokens.length

        last = curr = 0
        while curr < max
          # re-calculate levels after emphasis/strikethrough turns some text nodes
          # into opening/closing tags
          level -= 1 if tokens[curr].nesting < 0 # closing tag
          tokens[curr].level = level
          level += 1 if tokens[curr].nesting > 0 # opening tag

          if tokens[curr].type == 'text' &&
              curr + 1 < max &&
              tokens[curr + 1].type == 'text'

            # collapse two adjacent text nodes
            tokens[curr + 1].content = tokens[curr].content + tokens[curr + 1].content
          else
            tokens[last] = tokens[curr] if curr != last

            last += 1
          end

          curr += 1
        end

        if curr != last
          tokens.slice!(last..max)
        end
      end
    end
  end
end
