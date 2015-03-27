# HTML block
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class HtmlBlock

      HTML_TAG_OPEN_RE  = /^<([a-zA-Z][a-zA-Z0-9]{0,14})[\s\/>]/
      HTML_TAG_CLOSE_RE = /^<\/([a-zA-Z][a-zA-Z0-9]{0,14})[\s>]/

      #------------------------------------------------------------------------------
      def self.isLetter(ch)
        lc = ch | 0x20; # to lower case
        return (lc >= 0x61) && (lc <= 0x7a)  # >= a and <= z
      end

      #------------------------------------------------------------------------------
      def self.html_block(state, startLine, endLine, silent)
        pos   = state.bMarks[startLine]
        max   = state.eMarks[startLine]
        shift = state.tShift[startLine]

        pos += shift

        return false if !state.md.options[:html]
        return false if shift > 3 || (pos + 2) >= max
        return false if state.src.charCodeAt(pos) != 0x3C    # < 

        ch = state.src.charCodeAt(pos + 1)

        if ch == 0x21 || ch == 0x3F #  ! or ?
          # Directive start / comment start / processing instruction start
          return true if silent

        elsif ch == 0x2F || isLetter(ch)  # /

          # Probably start or end of tag
          if ch == 0x2F   # \
            # closing tag
            match = state.src.slice(pos...max).match(HTML_TAG_CLOSE_RE)
            return false if (!match)
          else
            # opening tag
            match = state.src.slice(pos...max).match(HTML_TAG_OPEN_RE)
            return false if !match
          end

          # Make sure tag name is valid
          return false if HTML_BLOCKS[match[1].downcase] != true
          return true if silent

        else
          return false
        end

        # If we are here - we detected HTML block.
        # Let's roll down till empty line (block end).
        nextLine = startLine + 1
        while nextLine < state.lineMax && !state.isEmpty(nextLine)
          nextLine += 1
        end

        state.line = nextLine

        token         = state.push('html_block', '', 0)
        token.map     = [ startLine, state.line ]
        token.content = state.getLines(startLine, nextLine, 0, true)

        return true
      end

    end
  end
end
