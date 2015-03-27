# Paragraph
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Paragraph

      #------------------------------------------------------------------------------
      def self.paragraph(state, startLine)
        nextLine        = startLine + 1
        terminatorRules = state.md.block.ruler.getRules('paragraph')
        endLine         = state.lineMax

        # jump line-by-line until empty one or EOF
        # for (; nextLine < endLine && !state.isEmpty(nextLine); nextLine++) {
        while nextLine < endLine && !state.isEmpty(nextLine)
          # this would be a code block normally, but after paragraph
          # it's considered a lazy continuation regardless of what's there
          (nextLine += 1) && next if (state.tShift[nextLine] - state.blkIndent > 3)

          # Some tags can terminate paragraph without empty line.
          terminate = false
          0.upto(terminatorRules.length - 1) do |i|
            if terminatorRules[i].call(state, nextLine, endLine, true)
              terminate = true
              break
            end
          end
          break if terminate
          nextLine += 1
        end

        content = state.getLines(startLine, nextLine, state.blkIndent, false).strip

        state.line = nextLine

        token          = state.push('paragraph_open', 'p', 1)
        token.map      = [ startLine, state.line ]

        token          = state.push('inline', '', 0)
        token.content  = content
        token.map      = [ startLine, state.line ]
        token.children = []

        token          = state.push('paragraph_close', 'p', -1)

        return true
      end

    end
  end
end
