# Normalize input string
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Normalize

      NEWLINES_RE  = /\r[\n\u0085]?|[\u2424\u2028\u0085]/
      NULL_RE      = /\u0000/

      #------------------------------------------------------------------------------
      def self.inline(state)
        # Normalize newlines
        str = state.src.gsub(NEWLINES_RE, "\n")

        # Replace NULL characters
        str = str.gsub(NULL_RE, '\uFFFD')

        state.src = str
      end
    end
  end
end