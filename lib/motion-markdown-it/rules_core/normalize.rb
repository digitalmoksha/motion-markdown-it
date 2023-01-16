# Normalize input string
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Normalize

      # https://spec.commonmark.org/0.29/#line-ending
      NEWLINES_RE  = /\r\n?|\n/
      NULL_RE      = /\0/

      #------------------------------------------------------------------------------
      def self.normalize(state)
        # Normalize newlines
        str = state.src.gsub(NEWLINES_RE, "\n")

        # Replace NULL characters
        str = str.gsub(NULL_RE, '\uFFFD')

        state.src = str
      end
    end
  end
end
