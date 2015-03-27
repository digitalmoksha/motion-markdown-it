# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Emphasis
      extend MarkdownIt::Common::Utils
      
      # parse sequence of emphasis markers,
      # "start" should point at a valid marker
      #------------------------------------------------------------------------------
      def self.scanDelims(state, start)
        pos       = start
        can_open  = true
        can_close = true
        max       = state.posMax
        marker    = state.src.charCodeAt(start)

        # treat beginning of the line as a whitespace
        lastChar = start > 0 ? state.src.charCodeAt(start - 1) : 0x20

        while (pos < max && state.src.charCodeAt(pos) == marker)
          pos += 1
        end

        if (pos >= max)
          can_open = false
        end

        count = pos - start

        # treat end of the line as a whitespace
        nextChar = pos < max ? state.src.charCodeAt(pos) : 0x20

        isLastPunctChar = isMdAsciiPunct(lastChar) || isPunctChar(lastChar.chr(Encoding::UTF_8))
        isNextPunctChar = isMdAsciiPunct(nextChar) || isPunctChar(nextChar.chr(Encoding::UTF_8))

        isLastWhiteSpace = isWhiteSpace(lastChar)
        isNextWhiteSpace = isWhiteSpace(nextChar)

        if (isNextWhiteSpace)
          can_open = false
        elsif (isNextPunctChar)
          if (!(isLastWhiteSpace || isLastPunctChar))
            can_open = false
          end
        end

        if (isLastWhiteSpace)
          can_close = false
        elsif (isLastPunctChar)
          if (!(isNextWhiteSpace || isNextPunctChar))
            can_close = false
          end
        end

        if (marker == 0x5F) # _
          if (can_open && can_close)
            # "_" inside a word can neither open nor close an emphasis
            can_open  = false
            can_close = isNextPunctChar
          end
        end

        return { can_open: can_open, can_close: can_close, delims: count }
      end

      #------------------------------------------------------------------------------
      def self.emphasis(state, silent)
        max    = state.posMax
        start  = state.pos
        marker = state.src.charCodeAt(start)

        return false if (marker != 0x5F && marker != 0x2A) #  _ *
        return false if (silent) # don't run any pairs in validation mode

        res = scanDelims(state, start)
        startCount = res[:delims]
        if (!res[:can_open])
          state.pos += startCount
          # Earlier we checked !silent, but this implementation does not need it
          state.pending += state.src.slice(start...state.pos)
          return true
        end

        state.pos = start + startCount
        stack = [ startCount ]

        while (state.pos < max)
          if (state.src.charCodeAt(state.pos) == marker)
            res = scanDelims(state, state.pos)
            count = res[:delims]
            if (res[:can_close])
              oldCount = stack.pop()
              newCount = count

              while (oldCount != newCount)
                if (newCount < oldCount)
                  stack.push(oldCount - newCount)
                  break
                end

                # assert(newCount > oldCount)
                newCount -= oldCount

                break if (stack.length == 0)
                state.pos += oldCount
                oldCount = stack.pop()
              end

              if (stack.length == 0)
                startCount = oldCount
                found      = true
                break
              end
              state.pos += count
              next
            end

            stack.push(count) if (res[:can_open])
            state.pos += count
            next
          end

          state.md.inline.skipToken(state)
        end

        if (!found)
          # parser failed to find ending tag, so it's not valid emphasis
          state.pos = start
          return false
        end

        # found!
        state.posMax = state.pos
        state.pos    = start + startCount

        # Earlier we checked !silent, but this implementation does not need it

        # we have `startCount` starting and ending markers,
        # now trying to serialize them into tokens
        count = startCount
        while count > 1
          token        = state.push('strong_open', 'strong', 1)
          token.markup = marker.chr + marker.chr
          count -= 2
        end
        if (count % 2 == 1)
          token        = state.push('em_open', 'em', 1)
          token.markup = marker.chr
        end

        state.md.inline.tokenize(state)

        if (count % 2 == 1)
          token        = state.push('em_close', 'em', -1)
          token.markup = marker.chr
        end
        count = startCount
        while count > 1
          token        = state.push('strong_close', 'strong', -1)
          token.markup = marker.chr + marker.chr
          count -= 2
        end

        state.pos     = state.posMax + startCount
        state.posMax  = max
        return true
      end

    end
  end
end
