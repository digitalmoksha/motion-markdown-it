# Convert straight quotation marks to typographic ones
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Smartquotes
      extend Common::Utils
      
      QUOTE_TEST_RE = /['"]/
      QUOTE_RE      = /['"]/
      APOSTROPHE    = "\u2019" # ’


      #------------------------------------------------------------------------------
      def self.replaceAt(str, index, ch)
        return str[0, index] + ch + str.slice_to_end(index + 1)
      end

      #------------------------------------------------------------------------------
      def self.process_inlines(tokens, state)
        stack = []

        (0...tokens.length).each do |i|
          token = tokens[i]

          thisLevel = tokens[i].level

          j = stack.length - 1
          while j >= 0
            break if (stack[j][:level] <= thisLevel)
            j -= 1
          end

          # stack.length = j + 1
          stack = (j < stack.length ? stack.slice(0, j + 1) : stack.fill(nil, stack.length...(j+1)))

          next if (token.type != 'text')
          
          text = token.content
          pos  = 0
          max  = text.length

          # OUTER loop
          while pos < max
            continue_outer_loop = false
            t = QUOTE_RE.match(text, pos)
            break if t.nil?

            canOpen  = true
            canClose = true
            pos      = t.begin(0) + 1
            isSingle = (t[0] == "'")

            # treat begin/end of the line as a whitespace
            lastChar = t.begin(0) - 1 >= 0 ? text.charCodeAt(t.begin(0) - 1) : 0x20
            nextChar = pos < max ? text.charCodeAt(pos) : 0x20

            isLastPunctChar = isMdAsciiPunct(lastChar) || isPunctChar(lastChar.chr(Encoding::UTF_8))
            isNextPunctChar = isMdAsciiPunct(nextChar) || isPunctChar(nextChar.chr(Encoding::UTF_8))

            isLastWhiteSpace = isWhiteSpace(lastChar)
            isNextWhiteSpace = isWhiteSpace(nextChar)

            if (isNextWhiteSpace)
              canOpen = false
            elsif (isNextPunctChar)
              if (!(isLastWhiteSpace || isLastPunctChar))
                canOpen = false
              end
            end

            if (isLastWhiteSpace)
              canClose = false
            elsif (isLastPunctChar)
              if (!(isNextWhiteSpace || isNextPunctChar))
                canClose = false
              end
            end

            if (nextChar == 0x22 && t[0] == '"') # "
              if (lastChar >= 0x30 && lastChar <= 0x39)   # >= 0  && <= 9
                # special case: 1"" - count first quote as an inch
                canClose = canOpen = false
              end
            end

            if (canOpen && canClose)
              # treat this as the middle of the word
              canOpen  = false
              canClose = isNextPunctChar
            end

            if (!canOpen && !canClose)
              # middle of word
              if (isSingle)
                token.content = replaceAt(token.content, t.begin(0), APOSTROPHE)
              end
              next
            end

            if (canClose)
              # this could be a closing quote, rewind the stack to get a match
              j = stack.length - 1
              while j >= 0
                item = stack[j]
                break if (stack[j][:level] < thisLevel)
                if (item[:single] == isSingle && stack[j][:level] == thisLevel)
                  item = stack[j]
                  if (isSingle)
                    tokens[item[:token]].content = replaceAt(tokens[item[:token]].content, item[:pos], state.md.options[:quotes][2])
                    token.content = replaceAt(token.content, t.begin(0), state.md.options[:quotes][3])
                  else
                    tokens[item[:token]].content = replaceAt(tokens[item[:token]].content, item[:pos], state.md.options[:quotes][0])
                    token.content = replaceAt(token.content, t.begin(0), state.md.options[:quotes][1])
                  end
                  # stack.length = j
                  stack = (j < stack.length ? stack.slice(0, j) : stack.fill(nil, stack.length...(j)))
                  continue_outer_loop = true    # continue OUTER;
                  break
                end
                j -= 1
              end
            end
            next if continue_outer_loop
            
            if (canOpen)
              stack.push({
                token: i,
                pos: t.begin(0),
                single: isSingle,
                level: thisLevel
              })
            elsif (canClose && isSingle)
              token.content = replaceAt(token.content, t.begin(0), APOSTROPHE)
            end
          end
        end
      end


      #------------------------------------------------------------------------------
      def self.smartquotes(state)
        return if (!state.md.options[:typographer])

        blkIdx = state.tokens.length - 1
        while blkIdx >= 0
          if (state.tokens[blkIdx].type != 'inline' || !(QUOTE_TEST_RE =~ state.tokens[blkIdx].content))
            blkIdx -= 1
            next
          end

          process_inlines(state.tokens[blkIdx].children, state)
          blkIdx -= 1
        end
      end
      
    end
  end
end
