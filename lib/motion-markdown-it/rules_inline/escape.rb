# Process escaped chars and hardbreaks
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Escape
      extend Common::Utils

      ESCAPED = []

      0.upto(255) { |i| ESCAPED.push(0) }

      '\\!"#$%&\'()*+,./:;<=>?@[]^_`{|}~-'.split('').each { |ch| ESCAPED[ch.ord] = 1 }

      #------------------------------------------------------------------------------
      def self.escape(state, silent)
        pos = state.pos
        max = state.posMax

        return false if charCodeAt(state.src, pos) != 0x5C    # \

        pos += 1

        # '\' at the end of the inline block
        return false if pos >= max

        ch1 = charCodeAt(state.src, pos)

        if ch1 == 0x0A
          if !silent
            state.push('hardbreak', 'br', 0)
          end

          pos += 1
          # skip leading whitespaces from next line
          while pos < max
            ch1 = charCodeAt(state.src, pos)
            break if !isSpace(ch1)
            pos += 1
          end

          state.pos = pos
          return true
        end

        escapedStr = state.src[pos]

        if (ch1 >= 0xD800 && ch1 <= 0xDBFF && pos + 1 < max)
          ch2 = charCodeAt(state.src, pos + 1)
      
          if (ch2 >= 0xDC00 && ch2 <= 0xDFFF)
            escapedStr += state.src[pos + 1]
            pos += 1
          end
        end

        origStr = '\\' + escapedStr

        if (!silent)
          token = state.push('text_special', '', 0)

          if ch1 < 256 && ESCAPED[ch1] != 0
            token.content = escapedStr
          else
            token.content = origStr
          end
  
          token.markup = origStr
          token.info   = 'escape'
        end

        state.pos = pos + 1
        return true
      end
    end
  end
end
