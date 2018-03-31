# Parser state class
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class StateBlock
      include MarkdownIt::Common::Utils

      attr_accessor     :src, :md, :env, :tokens, :bMarks, :eMarks, :tShift, :sCount
      attr_accessor     :blkIndent, :line, :lineMax, :tight, :parentType, :ddIndent
      attr_accessor     :level, :result

      #------------------------------------------------------------------------------
      def initialize(src, md, env, tokens)
        @src = src

        # link to parser instance
        @md  = md
        @env = env

        #--- Internal state variables

        @tokens = tokens

        @bMarks = []  # line begin offsets for fast jumps
        @eMarks = []  # line end offsets for fast jumps
        @tShift = []  # offsets of the first non-space characters (tabs not expanded)
        @sCount = []  # indents for each line (tabs expanded)

        # block parser variables
        @blkIndent  = 0       # required block content indent (for example, if we are in list)
        @line       = 0       # line index in src
        @lineMax    = 0       # lines count
        @tight      = false   # loose/tight mode for lists
        @parentType = 'root'  # if `list`, block parser stops on two newlines
        @ddIndent   = -1      # indent of the current dd block (-1 if there isn't any)

        @level = 0

        # renderer
        @result = ''

        # Create caches
        # Generate markers.
        s            = @src
        indent_found = false

        start = pos = indent = offset = 0
        len = s.length
        while pos < len
          ch = s.charCodeAt(pos)

          if !indent_found
            if isSpace(ch)
              indent += 1

              if ch == 0x09
                offset += 4 - offset % 4
              else
                offset += 1
              end
              (pos += 1) && next
            else
              indent_found = true
            end
          end

          if ch == 0x0A || pos == (len - 1)
            pos += 1 if ch != 0x0A
            @bMarks.push(start)
            @eMarks.push(pos)
            @tShift.push(indent)
            @sCount.push(offset)

            indent_found = false
            indent       = 0
            offset       = 0
            start        = pos + 1
          end

          pos += 1
        end

        # Push fake entry to simplify cache bounds checks
        @bMarks.push(s.length)
        @eMarks.push(s.length)
        @tShift.push(0)
        @sCount.push(0)

        @lineMax = @bMarks.length - 1 # don't count last fake line
      end

      # Push new token to "stream".
      #------------------------------------------------------------------------------
      def push(type, tag, nesting)
        token       = Token.new(type, tag, nesting)
        token.block = true

        @level -= 1 if nesting < 0
        token.level = @level
        @level += 1 if nesting > 0

        @tokens.push(token)
        return token
      end

      #------------------------------------------------------------------------------
      def isEmpty(line)
        return @bMarks[line] + @tShift[line] >= @eMarks[line]
      end

      #------------------------------------------------------------------------------
      def skipEmptyLines(from)
        while from < @lineMax
          break if (@bMarks[from] + @tShift[from] < @eMarks[from])
          from += 1
        end
        return from
      end

      # Skip spaces from given position.
      #------------------------------------------------------------------------------
      def skipSpaces(pos)
        max = @src.length
        while pos < max
          ch = @src.charCodeAt(pos)
          break if !isSpace(ch)
          pos += 1
        end
        return pos
      end

      # Skip spaces from given position in reverse.
      #------------------------------------------------------------------------------
      def skipSpacesBack(pos, min)
        return pos if pos <= min

        while (pos > min)
          return pos + 1 if !isSpace(@src.charCodeAt(pos -= 1))
        end
        return pos
      end

      # Skip char codes from given position
      #------------------------------------------------------------------------------
      def skipChars(pos, code)
        max = @src.length
        while pos < max
          break if (@src.charCodeAt(pos) != code)
          pos += 1
        end
        return pos
      end

      # Skip char codes reverse from given position - 1
      #------------------------------------------------------------------------------
      def skipCharsBack(pos, code, min)
        return pos if pos <= min

        while (pos > min)
          return (pos + 1) if code != @src.charCodeAt(pos -= 1)
        end
        return pos
      end

      # cut lines range from source.
      #------------------------------------------------------------------------------
      def getLines(line_begin, line_end, indent, keepLastLF)
        line = line_begin

        return '' if line_begin >= line_end

        queue = Array.new(line_end - line_begin)

        i = 0
        while line < line_end
          lineIndent = 0
          lineStart = first = @bMarks[line]

          if line + 1 < line_end || keepLastLF
            # No need for bounds check because we have fake entry on tail.
            last = @eMarks[line] + 1
          else
            last = @eMarks[line]
          end

          while first < last && lineIndent < indent
            ch = @src.charCodeAt(first)

            if isSpace(ch)
              if ch === 0x09
                lineIndent += 4 - lineIndent % 4
              else
                lineIndent += 1
              end
            elsif first - lineStart < @tShift[line]
              # patched tShift masked characters to look like spaces (blockquotes, list markers)
              lineIndent += 1
            else
              break
            end

            first += 1
          end

          queue[i] = @src.slice(first...last)
          line += 1
          i    += 1
        end

        return queue.join('')
      end

    end
  end
end