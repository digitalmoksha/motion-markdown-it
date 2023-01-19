# Join raw text tokens with the rest of the text
#
# This is set as a separate rule to provide an opportunity for plugins
# to run text replacements after text join, but before escape join.
#
# For example, `\:)` shouldn't be replaced with an emoji.
#
module MarkdownIt
  module RulesCore
    class TextJoin
      def self.text_join(state)
        blockTokens = state.tokens

        (0...blockTokens.length).each do |j|
          next if (blockTokens[j].type != 'inline')
      
          tokens = blockTokens[j].children
          max = tokens.length
      
          (0...max).each do |curr|
            if (tokens[curr].type == 'text_special')
              tokens[curr].type = 'text'
            end
          end

          last = 0
          curr = 0
          while curr < max
            if (tokens[curr].type == 'text' &&
                curr + 1 < max &&
                tokens[curr + 1].type == 'text')
      
              # collapse two adjacent text nodes
              tokens[curr + 1].content = tokens[curr].content + tokens[curr + 1].content
            else
               tokens[last] = tokens[curr] if (curr != last)
      
              last += 1
            end
            
            curr += 1
          end
      
          if (curr != last)
            tokens.pop(tokens.length - last)
          end
        end
      end
    end
  end
end
