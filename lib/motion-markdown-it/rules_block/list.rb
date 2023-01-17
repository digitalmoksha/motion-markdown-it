# Lists
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class List
      extend Common::Utils

      # Search `[-+*][\n ]`, returns next pos after marker on success
      # or -1 on fail.
      #------------------------------------------------------------------------------
      def self.skipBulletListMarker(state, startLine)
        pos = state.bMarks[startLine] + state.tShift[startLine]
        max = state.eMarks[startLine]

        marker = charCodeAt(state.src, pos)
        pos   += 1
        # Check bullet
        if (marker != 0x2A && # *
            marker != 0x2D && # -
            marker != 0x2B)   # +
          return -1
        end

        if pos < max
          ch = charCodeAt(state.src, pos)

          if !isSpace(ch)
            # " -test " - is not a list item
            return -1
          end
        end

        return pos
      end

      # Search `\d+[.)][\n ]`, returns next pos after marker on success
      # or -1 on fail.
      #------------------------------------------------------------------------------
      def self.skipOrderedListMarker(state, startLine)
        start = state.bMarks[startLine] + state.tShift[startLine]
        pos   = start
        max   = state.eMarks[startLine]

        # List marker should have at least 2 chars (digit + dot)
        return -1 if (pos + 1 >= max)

        ch   = charCodeAt(state.src, pos)
        pos += 1

        return -1 if ch.nil?
        return -1 if (ch < 0x30 || ch > 0x39) # < 0 || > 9

        while true
          # EOL -> fail
          return -1 if (pos >= max)

          ch   = charCodeAt(state.src, pos)
          pos += 1

          if (ch >= 0x30 && ch <= 0x39) #  >= 0 && <= 9

            # List marker should have no more than 9 digits
            # (prevents integer overflow in browsers)
            return -1 if pos - start >= 10

            next
          end

          # found valid marker
          if (ch === 0x29 || ch === 0x2e) # ')' || '.'
            break
          end

          return -1
        end

        if pos < max
          ch = charCodeAt(state.src, pos)

          if !isSpace(ch)
            # " 1.test " - is not a list item
            return -1
          end
        end
        return pos
      end

      #------------------------------------------------------------------------------
      def self.markTightParagraphs(state, idx)
        level = state.level + 2

        i = idx + 2
        l =  state.tokens.length
        while i < l
          if (state.tokens[i].level == level && state.tokens[i].type == 'paragraph_open')
            state.tokens[i + 2].hidden = true
            state.tokens[i].hidden     = true
            i += 2
          end
          i += 1
        end
      end

      #------------------------------------------------------------------------------
      def self.list(state, startLine, endLine, silent)
        isTerminatingParagraph = false
        tight = true

        # if it's indented more than 3 spaces, it should be a code block
        return false if (state.sCount[startLine] - state.blkIndent >= 4)

        # Special case:
        #  - item 1
        #   - item 2
        #    - item 3
        #     - item 4
        #      - this one is a paragraph continuation
        if (state.listIndent >= 0 &&
            state.sCount[startLine] - state.listIndent >= 4 &&
            state.sCount[startLine] < state.blkIndent)
          return false
        end

        # limit conditions when list can interrupt
        # a paragraph (validation mode only)
        if silent && state.parentType == 'paragraph'
          # Next list item should still terminate previous list item;
          #
          # This code can fail if plugins use blkIndent as well as lists,
          # but I hope the spec gets fixed long before that happens.
          #
          if state.sCount[startLine] >= state.blkIndent
            isTerminatingParagraph = true
          end
        end

        # Detect list type and position after marker
        if ((posAfterMarker = skipOrderedListMarker(state, startLine)) >= 0)
          isOrdered   = true
          start       = state.bMarks[startLine] + state.tShift[startLine]
          markerValue = state.src[start, posAfterMarker - 1].to_i

          # If we're starting a new ordered list right after
          # a paragraph, it should start with 1.
          return false if isTerminatingParagraph && markerValue != 1
        elsif ((posAfterMarker = skipBulletListMarker(state, startLine)) >= 0)
          isOrdered = false
        else
          return false
        end

        # If we're starting a new unordered list right after
        # a paragraph, first line should not be empty.
        if isTerminatingParagraph
          return false if state.skipSpaces(posAfterMarker) >= state.eMarks[startLine]
        end

        # We should terminate list on style change. Remember first one to compare.
        markerCharCode = charCodeAt(state.src, posAfterMarker - 1)

        # For validation mode we can terminate immediately
        return true if (silent)

        # Start list
        listTokIdx = state.tokens.length

        if (isOrdered)
          start       = state.bMarks[startLine] + state.tShift[startLine]
          markerValue = state.src[start, posAfterMarker - start - 1].to_i
          token       = state.push('ordered_list_open', 'ol', 1)
          if (markerValue != 1)
            token.attrs = [ [ 'start', markerValue ] ]
          end

        else
          token       = state.push('bullet_list_open', 'ul', 1)
        end

        token.map    = listLines = [ startLine, 0 ]
        token.markup = markerCharCode.chr

        #
        # Iterate list items
        #

        nextLine        = startLine
        prevEmptyEnd    = false
        terminatorRules = state.md.block.ruler.getRules('list')

        oldParentType    = state.parentType
        state.parentType = 'list'

        while (nextLine < endLine)
          pos          = posAfterMarker
          max          = state.eMarks[nextLine]

          initial = offset = state.sCount[nextLine] + posAfterMarker - (state.bMarks[startLine] + state.tShift[startLine])

          while pos < max
            ch = charCodeAt(state.src, pos)

            if ch == 0x09
              offset += 4 - (offset + state.bsCount[nextLine]) % 4
            elsif ch == 0x20
              offset += 1
            else
              break
            end

            pos += 1
          end

          contentStart = pos

          if (contentStart >= max)
            # trimming space in "-    \n  3" case, indent is 1 here
            indentAfterMarker = 1
          else
            indentAfterMarker = offset - initial
          end

          # If we have more than 4 spaces, the indent is 1
          # (the rest is just indented code block)
          indentAfterMarker = 1 if (indentAfterMarker > 4)

          # "  -  test"
          #  ^^^^^ - calculating total length of this thing
          indent = initial + indentAfterMarker

          # Run subparser & write tokens
          token        = state.push('list_item_open', 'li', 1)
          token.markup = markerCharCode.chr
          token.map    = itemLines = [ startLine, 0 ]
          if (isOrdered)
            token.info = state.src.slice(start...posAfterMarker - 1)
          end

          # change current state, then restore it after parser subcall
          oldTight                = state.tight
          oldTShift               = state.tShift[startLine]
          oldSCount               = state.sCount[startLine]

          #  - example list
          # ^ listIndent position will be here
          #   ^ blkIndent position will be here
          #
          oldListIndent           = state.listIndent
          state.listIndent        = state.blkIndent
          state.blkIndent         = indent

          state.tight             = true
          state.tShift[startLine] = contentStart - state.bMarks[startLine]
          state.sCount[startLine] = offset

          if contentStart >= max && state.isEmpty(startLine + 1)
            # workaround for this case
            # (list item is empty, list terminates before "foo"):
            # ~~~~~~~~
            #   -
            #
            #     foo
            # ~~~~~~~~
            state.line = [state.line + 2, endLine].min
          else
            state.md.block.tokenize(state, startLine, endLine, true)
          end

          # If any of list item is tight, mark list as tight
          if (!state.tight || prevEmptyEnd)
            tight = false
          end
          # Item become loose if finish with empty line,
          # but we should filter last element, because it means list finish
          prevEmptyEnd = (state.line - startLine) > 1 && state.isEmpty(state.line - 1)

          state.blkIndent         = state.listIndent
          state.listIndent        = oldListIndent
          state.tShift[startLine] = oldTShift
          state.sCount[startLine] = oldSCount
          state.tight             = oldTight

          token                   = state.push('list_item_close', 'li', -1)
          token.markup            = markerCharCode.chr

          nextLine                = startLine = state.line
          itemLines[1]            = nextLine
          contentStart            = state.bMarks[startLine]

          break if (nextLine >= endLine)

          #
          # Try to check if list is terminated or continued.
          #
          break if (state.sCount[nextLine] < state.blkIndent)

          # if it's indented more than 3 spaces, it should be a code block
          break if (state.sCount[startLine] - state.blkIndent >= 4)

          # fail if terminating block found
          terminate = false
          (0...terminatorRules.length).each do |i|
            if (terminatorRules[i].call(state, nextLine, endLine, true))
              terminate = true
              break
            end
          end
          break if (terminate)

          # fail if list has another type
          if (isOrdered)
            posAfterMarker = skipOrderedListMarker(state, nextLine)
            break if (posAfterMarker < 0)
            start = state.bMarks[nextLine] + state.tShift[nextLine]
          else
            posAfterMarker = skipBulletListMarker(state, nextLine)
            break if (posAfterMarker < 0)
          end

          break if (markerCharCode != charCodeAt(state.src, posAfterMarker - 1))
        end

        # Finalize list
        if (isOrdered)
          token = state.push('ordered_list_close', 'ol', -1)
        else
          token = state.push('bullet_list_close', 'ul', -1)
        end
        token.markup = markerCharCode.chr

        listLines[1] = nextLine
        state.line   = nextLine

        state.parentType = oldParentType

        # mark paragraphs tight if needed
        if (tight)
          markTightParagraphs(state, listTokIdx)
        end

        return true
      end

    end
  end
end
