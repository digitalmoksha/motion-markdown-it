# HTML block
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class HtmlBlock
      extend Common::Utils

      HTML_OPEN_CLOSE_TAG_RE = MarkdownIt::Common::HtmlRe::HTML_OPEN_CLOSE_TAG_RE

      # An array of opening and corresponding closing sequences for html tags,
      # last argument defines whether it can terminate a paragraph or not
      #
      HTML_SEQUENCES = [
        [ /^<(script|pre|style|textarea)(?=(\s|>|$))/i, /<\/(script|pre|style|textarea)>/i, true ],
        [ /^<!--/,        /-->/,   true ],
        [ /^<\?/,         /\?>/,   true ],
        [ /^<![A-Z]/,     />/,     true ],
        [ /^<!\[CDATA\[/, /\]\]>/, true ],
        [ Regexp.new('^</?(' + MarkdownIt::HTML_BLOCKS.join('|') + ')(?=(\\s|/?>|$))', 'i'), /^$/, true ],
        [ Regexp.new(HTML_OPEN_CLOSE_TAG_RE.source + '\\s*$'),  /^$/, false ]
      ];

      #------------------------------------------------------------------------------
      def self.html_block(state, startLine, endLine, silent)
        pos   = state.bMarks[startLine] + state.tShift[startLine]
        max   = state.eMarks[startLine]

        # if it's indented more than 3 spaces, it should be a code block
        return false if state.sCount[startLine] - state.blkIndent >= 4

        return false if !state.md.options[:html]
        return false if charCodeAt(state.src, pos) != 0x3C    # <

        lineText = state.src.slice(pos...max)

        i = 0
        while i < HTML_SEQUENCES.length
          break if HTML_SEQUENCES[i][0].match(lineText)
          i += 1
        end

        return false if i == HTML_SEQUENCES.length

        if silent
          # true if this sequence can be a terminator, false otherwise
          return HTML_SEQUENCES[i][2]
        end

        nextLine = startLine + 1

        # If we are here - we detected HTML block.
        # Let's roll down till block end.
        if !HTML_SEQUENCES[i][1].match(lineText)
          while nextLine < endLine
            break if state.sCount[nextLine] < state.blkIndent

            pos = state.bMarks[nextLine] + state.tShift[nextLine]
            max = state.eMarks[nextLine]
            lineText = state.src.slice(pos...max)

            if HTML_SEQUENCES[i][1].match(lineText)
              nextLine += 1 if lineText.length != 0
              break
            end
            nextLine += 1
          end
        end

        state.line = nextLine

        token         = state.push('html_block', '', 0)
        token.map     = [ startLine, nextLine ]
        token.content = state.getLines(startLine, nextLine, state.blkIndent, true)

        return true
      end

    end
  end
end
