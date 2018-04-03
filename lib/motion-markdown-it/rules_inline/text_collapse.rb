# Merge adjacent text nodes into one, and re-calculate all token levels
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
          # re-calculate levels
          level += tokens[curr].nesting
          tokens[curr].level = level

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
