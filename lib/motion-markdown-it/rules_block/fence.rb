# fences (``` lang, ~~~ lang)
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Fence

      #------------------------------------------------------------------------------
      def self.fence(state, startLine, endLine, silent)
        haveEndMarker = false
        pos           = state.bMarks[startLine] + state.tShift[startLine]
        max           = state.eMarks[startLine]

        return false if pos + 3 > max

        marker = state.src.charCodeAt(pos)

        if marker != 0x7E && marker != 0x60 #  != ~ && != `
          return false
        end

        # scan marker length
        mem = pos;
        pos = state.skipChars(pos, marker)
        len = pos - mem

        return false if len < 3

        markup = state.src.slice(mem...pos)
        params = state.src.slice(pos...max)

        return false if params.include?('`')

        # Since start is found, we can report success here in validation mode
        return true if silent

        # search end of block
        nextLine = startLine

        while true
          nextLine += 1
          if nextLine >= endLine
            # unclosed block should be autoclosed by end of document.
            # also block seems to be autoclosed by end of parent
            break
          end

          pos = mem = state.bMarks[nextLine] + state.tShift[nextLine]
          max = state.eMarks[nextLine];

          if pos < max && state.sCount[nextLine] < state.blkIndent
            # non-empty line with negative indent should stop the list:
            # - ```
            #  test
            break
          end

          next if state.src.charCodeAt(pos) != marker

          if state.sCount[nextLine] - state.blkIndent >= 4
            # closing fence should be indented less than 4 spaces
            next
          end

          pos = state.skipChars(pos, marker)

          # closing code fence must be at least as long as the opening one
          next if pos - mem < len

          # make sure tail has spaces only
          pos = state.skipSpaces(pos)

          next if pos < max

          haveEndMarker = true
          # found!
          break
        end

        # If a fence has heading spaces, they should be removed from its inner block
        len           = state.sCount[startLine]

        state.line    = nextLine + (haveEndMarker ? 1 : 0)

        token         = state.push('fence', 'code', 0)
        token.info    = params
        token.content = state.getLines(startLine + 1, nextLine, len, true)
        token.markup  = markup
        token.map     = [ startLine, state.line ]

        return true
      end

    end
  end
end
