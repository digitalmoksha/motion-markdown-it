# Horizontal rule
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Hr
      extend Common::Utils

      #------------------------------------------------------------------------------
      def self.hr(state, startLine, endLine, silent)
        pos    = state.bMarks[startLine] + state.tShift[startLine]
        max    = state.eMarks[startLine]
        marker = state.src.charCodeAt(pos)
        pos   += 1

        # Check hr marker
        if (marker != 0x2A &&  # *
            marker != 0x2D &&  # -
            marker != 0x5F)    # _
          return false
        end

        # markers can be mixed with spaces, but there should be at least 3 of them

        cnt = 1
        while (pos < max)
          ch   = state.src.charCodeAt(pos)
          pos += 1
          return false if ch != marker && !isSpace(ch)
          cnt += 1 if ch == marker
        end

        return false if cnt < 3
        return true if silent

        state.line = startLine + 1

        token        = state.push('hr', 'hr', 0)
        token.map    = [ startLine, state.line ]
        token.markup = marker.chr * (cnt + 1)

        return true
      end

    end
  end
end
