# GFM table, https://github.github.com/gfm/#tables-extension-
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Table
      extend Common::Utils

      #------------------------------------------------------------------------------
      def self.getLine(state, line)
        pos = state.bMarks[line] + state.tShift[line]
        max = state.eMarks[line]

        return state.src[pos, max - pos]
      end

      #------------------------------------------------------------------------------
      def self.escapedSplit(str)
        result       = []
        pos          = 0
        max          = str.length
        isEscaped    = false
        lastPos      = 0
        current      = ''

        ch           = charCodeAt(str, pos)

        while (pos < max)
          if ch == 0x7c  # |
            if (!isEscaped)
              # pipe separating cells, '|'
              result.push(current + str[lastPos...pos])
              current = ''
              lastPos = pos + 1
            else
              # escaped pipe, '\|'
              current += str[lastPos...(pos - 1)]
              lastPos = pos
            end
          end

          isEscaped = (ch == 0x5c)   # '\'
          pos += 1

          ch = charCodeAt(str, pos)
        end

        result.push(current + str[lastPos..-1])

        return result
      end

      #------------------------------------------------------------------------------
      def self.table(state, startLine, endLine, silent)
        # should have at least two lines
        return false if (startLine + 2 > endLine)

        nextLine = startLine + 1

        return false if (state.sCount[nextLine] < state.blkIndent)

        # if it's indented more than 3 spaces, it should be a code block
        return false if state.sCount[nextLine] - state.blkIndent >= 4

        # first character of the second line should be '|', '-', ':',
        # and no other characters are allowed but spaces;
        # basically, this is the equivalent of /^[-:|][-:|\s]*$/ regexp

        pos = state.bMarks[nextLine] + state.tShift[nextLine]
        return false if (pos >= state.eMarks[nextLine])

        ch = charCodeAt(state.src, pos)
        pos += 1
        return false if (ch != 0x7C && ch != 0x2D && ch != 0x3A) # | or  - or :

        while pos < state.eMarks[nextLine]
          ch = charCodeAt(state.src, pos)
          return false if (ch != 0x7C && ch != 0x2D && ch != 0x3A && !isSpace(ch)) # | or - or :

          pos += 1
        end

        lineText = getLine(state, startLine + 1)

        columns = lineText.split('|')
        aligns = []
        (0...columns.length).each do |i|
          t = columns[i].strip
          if t.empty?
            # allow empty columns before and after table, but not in between columns
            # e.g. allow ` |---| `, disallow ` ---||--- `
            if (i == 0 || i == columns.length - 1)
              next
            else
              return false
            end
          end

          return false if (/^:?-+:?$/ =~ t).nil?
          if (charCodeAt(t, t.length - 1) == 0x3A)  # ':'
            aligns.push(charCodeAt(t, 0) == 0x3A ? 'center' : 'right')
          elsif (charCodeAt(t, 0) == 0x3A)
            aligns.push('left')
          else
            aligns.push('')
          end
        end

        lineText = getLine(state, startLine).strip
        return false if !lineText.include?('|')
        return false if state.sCount[startLine] - state.blkIndent >= 4
        columns = self.escapedSplit(lineText)

        columns.shift if (columns.length && columns[0] == '') 
        columns.pop if (columns.length && columns[columns.length - 1] == '')

        # header row will define an amount of columns in the entire table,
        # and align row should be exactly the same (the rest of the rows can differ)
        columnCount = columns.length
        return false if columnCount == 0 || columnCount != aligns.length

        return true  if silent

        oldParentType = state.parentType
        state.parentType = 'table'
      
        # use 'blockquote' lists for termination because it's
        # the most similar to tables
        terminatorRules = state.md.block.ruler.getRules('blockquote')

        token     = state.push('table_open', 'table', 1)
        token.map = tableLines = [ startLine, 0 ]

        token     = state.push('thead_open', 'thead', 1)
        token.map = [ startLine, startLine + 1 ]

        token     = state.push('tr_open', 'tr', 1)
        token.map = [ startLine, startLine + 1 ]

        (0...columns.length).each do |i|
          token          = state.push('th_open', 'th', 1)
          unless aligns[i].empty?
            token.attrs  = [ [ 'style', 'text-align:' + aligns[i] ] ]
          end

          token          = state.push('inline', '', 0)
          token.content  = columns[i].strip
          token.children = []

          token          = state.push('th_close', 'th', -1)
        end

        token     = state.push('tr_close', 'tr', -1)
        token     = state.push('thead_close', 'thead', -1)

        nextLine = startLine + 2
        while nextLine < endLine
          break if (state.sCount[nextLine] < state.blkIndent)

          terminate = false
          (0...terminatorRules.length).each do |i|
            if (terminatorRules[i].call(state, nextLine, endLine, true))
              terminate = true
              break
            end
          end
      
          break if (terminate)

          lineText = getLine(state, nextLine).strip
          break if lineText.empty?
          break if state.sCount[nextLine] - state.blkIndent >= 4
          columns = self.escapedSplit(lineText)
          columns.shift if (columns.length && columns[0] == '')
          columns.pop if (columns.length && columns[columns.length - 1] == '')
      
          if (nextLine == startLine + 2)
            token     = state.push('tbody_open', 'tbody', 1)
            token.map = tbodyLines = [ startLine + 2, 0 ]
          end
      
          token     = state.push('tr_open', 'tr', 1)
          token.map = [ nextLine, nextLine + 1 ]

          (0...columnCount).each do |i|
            token          = state.push('td_open', 'td', 1)
            token.map      = [ nextLine, nextLine + 1 ]
            unless aligns[i].empty?
              token.attrs  = [ [ 'style', 'text-align:' + aligns[i] ] ]
            end

            token          = state.push('inline', '', 0)
            token.content  = columns[i] ? columns[i].strip : ''
            token.children = []

            token          = state.push('td_close', 'td', -1)
          end
          token = state.push('tr_close', 'tr', -1)
          nextLine += 1
        end

        if (tbodyLines)
          token = state.push('tbody_close', 'tbody', -1)
          tbodyLines[1] = nextLine
        end

        token = state.push('table_close', 'table', -1)
        tableLines[1] = nextLine

        state.parentType = oldParentType
        state.line = nextLine
        return true
      end

    end
  end
end
