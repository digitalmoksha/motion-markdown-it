# Process html tags
#------------------------------------------------------------------------------
module MarkdownIt

  module RulesInline
    class HtmlInline
      include MarkdownIt::Common::HtmlRe
      
      #------------------------------------------------------------------------------
      def self.isLetter(ch)
        lc = ch | 0x20    # to lower case
        return (lc >= 0x61) && (lc <= 0x7a)  # >= a && <= z
      end

      #------------------------------------------------------------------------------
      def self.html_inline(state, silent)
        pos = state.pos

        return false if !state.md.options[:html]

        # Check start
        max = state.posMax
        if (state.src.charCodeAt(pos) != 0x3C || pos + 2 >= max)  #  < 
          return false
        end

        # Quick fail on second char
        ch = state.src.charCodeAt(pos + 1)
        if (ch != 0x21 &&  # !
            ch != 0x3F &&  # ?
            ch != 0x2F &&  # /
            !isLetter(ch))
          return false
        end

        match = state.src.slice_to_end(pos).match(HTML_TAG_RE)
        return false if !match

        if !silent
          token         = state.push('html_inline', '', 0)
          token.content = state.src.slice(pos...(pos + match[0].length))
        end
        state.pos += match[0].length
        return true
      end

    end
  end
end
