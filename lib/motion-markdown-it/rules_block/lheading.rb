# lheading (---, ===)
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Lheading

      #------------------------------------------------------------------------------
      def self.lheading(state, startLine, endLine, silent = true)
        nextLine = startLine + 1

        return false if (nextLine >= endLine)
        return false if (state.tShift[nextLine] < state.blkIndent)

        # Scan next line

        return false if (state.tShift[nextLine] - state.blkIndent > 3)

        pos = state.bMarks[nextLine] + state.tShift[nextLine]
        max = state.eMarks[nextLine]

        return false if (pos >= max)

        marker = state.src.charCodeAt(pos)

        return false if (marker != 0x2D && marker != 0x3D) # != '-' && != '='

        pos = state.skipChars(pos, marker)
        pos = state.skipSpaces(pos)

        return false if (pos < max)

        pos = state.bMarks[startLine] + state.tShift[startLine]

        state.line = nextLine + 1
        level = (marker == 0x3D ? 1 : 2) # =

        token          = state.push('heading_open', "h#{level.to_s}", 1)
        token.markup   = marker.chr
        token.map      = [ startLine, state.line ]

        token          = state.push('inline', '', 0)
        token.content  = state.src.slice(pos...state.eMarks[startLine]).strip
        token.map      = [ startLine, state.line - 1 ]
        token.children = []

        token          = state.push('heading_close', "h#{level.to_s}", -1)
        token.markup   = marker.chr

        return true
      end

    end
  end
end
