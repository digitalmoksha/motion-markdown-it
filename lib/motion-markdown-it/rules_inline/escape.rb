# Proceess escaped chars and hardbreaks
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

        return false if state.src.charCodeAt(pos) != 0x5C    # \

        pos += 1

        if pos < max
          ch = state.src.charCodeAt(pos)

          if ch < 256 && ESCAPED[ch] != 0
            state.pending += state.src[pos] if !silent
            state.pos     += 2
            return true
          end

          if ch == 0x0A
            if !silent
              state.push('hardbreak', 'br', 0)
            end

            pos += 1
            # skip leading whitespaces from next line
            while pos < max
              ch = state.src.charCodeAt(pos)
              break if !isSpace(ch)
              pos += 1
            end

            state.pos = pos
            return true
          end
        end

        state.pending += '\\' if !silent
        state.pos += 1
        return true
      end
    end
  end
end
