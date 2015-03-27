# Code block (4 spaces padded)
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Code

      #------------------------------------------------------------------------------
      def self.code(state, startLine, endLine, silent = true)
        return false if (state.tShift[startLine] - state.blkIndent < 4)

        last = nextLine = startLine + 1
        while nextLine < endLine
          if state.isEmpty(nextLine)
            nextLine += 1
            next
          end
          if (state.tShift[nextLine] - state.blkIndent >= 4)
            nextLine += 1
            last = nextLine
            next
          end
          break
        end

        state.line    = nextLine

        token         = state.push('code_block', 'code', 0)
        token.content = state.getLines(startLine, last, 4 + state.blkIndent, true)
        token.map     = [ startLine, state.line ]
        return true
      end

    end
  end
end
