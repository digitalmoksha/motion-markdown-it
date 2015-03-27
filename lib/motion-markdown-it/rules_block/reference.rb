module MarkdownIt
  module RulesBlock
    class Reference
      extend Helpers::ParseLinkDestination
      extend Helpers::ParseLinkTitle
      extend Common::Utils
      
      #------------------------------------------------------------------------------
      def self.reference(state, startLine, _endLine, silent)
        lines    = 0
        pos      = state.bMarks[startLine] + state.tShift[startLine]
        max      = state.eMarks[startLine]
        nextLine = startLine + 1

        return false if (state.src.charCodeAt(pos) != 0x5B) # [

        # Simple check to quickly interrupt scan on [link](url) at the start of line.
        # Can be useful on practice: https://github.com/markdown-it/markdown-it/issues/54
        pos += 1
        while (pos < max)
          if (state.src.charCodeAt(pos) == 0x5D &&    # ]
              state.src.charCodeAt(pos - 1) != 0x5C)  # \
            return false if (pos + 1 === max)
            return false if (state.src.charCodeAt(pos + 1) != 0x3A)  # :
            break
          end
          pos += 1
        end

        endLine = state.lineMax

        # jump line-by-line until empty one or EOF
        terminatorRules = state.md.block.ruler.getRules('reference')

        while nextLine < endLine && !state.isEmpty(nextLine)
          nextLine += 1
          # this would be a code block normally, but after paragraph
          # it's considered a lazy continuation regardless of what's there
          next if (state.tShift[nextLine] - state.blkIndent > 3)

          # Some tags can terminate paragraph without empty line.
          terminate = false
          (0...terminatorRules.length).each do |i|
            if (terminatorRules[i].call(state, nextLine, endLine, true))
              terminate = true
              break
            end
          end
          break if (terminate)
        end

        str      = state.getLines(startLine, nextLine, state.blkIndent, false).strip
        max      = str.length
        labelEnd = -1

        pos = 1
        while pos < max
          ch = str.charCodeAt(pos)
          if (ch == 0x5B ) # [ 
            return false
          elsif (ch == 0x5D) # ]
            labelEnd = pos
            break
          elsif (ch == 0x0A) # \n
            lines += 1
          elsif (ch == 0x5C) # \
            pos += 1
            if (pos < max && str.charCodeAt(pos) == 0x0A)
              lines += 1
            end
          end
          pos += 1
        end

        return false if (labelEnd < 0 || str.charCodeAt(labelEnd + 1) != 0x3A) # :

        # [label]:   destination   'title'
        #         ^^^ skip optional whitespace here
        pos = labelEnd + 2
        while pos < max
          ch = str.charCodeAt(pos)
          if (ch == 0x0A)
            lines += 1
          elsif (ch == 0x20)
          else
            break
          end
          pos += 1
        end

        # [label]:   destination   'title'
        #            ^^^^^^^^^^^ parse this
        res = parseLinkDestination(str, pos, max)
        return false if (!res[:ok])

        href = state.md.normalizeLink.call(res[:str])
        return false if (!state.md.validateLink.call(href))

        pos    = res[:pos]
        lines += res[:lines]

        # save cursor state, we could require to rollback later
        destEndPos    = pos
        destEndLineNo = lines

        # [label]:   destination   'title'
        #                       ^^^ skipping those spaces
        start = pos
        while (pos < max)
          ch = str.charCodeAt(pos)
          if (ch == 0x0A)
            lines += 1
          elsif (ch == 0x20)
          else
            break
          end
          pos += 1
        end

        # [label]:   destination   'title'
        #                          ^^^^^^^ parse this
        res = parseLinkTitle(str, pos, max)
        if (pos < max && start != pos && res[:ok])
          title  = res[:str]
          pos    = res[:pos]
          lines += res[:lines]
        else
          title = ''
          pos   = destEndPos
          lines = destEndLineNo
        end

        # skip trailing spaces until the rest of the line
        while (pos < max && str.charCodeAt(pos) == 0x20)  # space
          pos += 1
        end

        if (pos < max && str.charCodeAt(pos) != 0x0A)
          # garbage at the end of the line
          return false
        end

        # Reference can not terminate anything. This check is for safety only.
        # istanbul ignore if
        return true if (silent)

        label = normalizeReference(str.slice(1...labelEnd))
        if (state.env[:references].nil?)
          state.env[:references] = {}
        end
        if state.env[:references][label].nil?
          state.env[:references][label] = { title: title, href: href }
        end

        state.line = startLine + lines + 1
        return true
      end

    end
  end
end
