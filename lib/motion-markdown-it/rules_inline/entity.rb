# Process html entity - &#123;, &#xAF;, &quot;, ...
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Entity
      extend Common::Utils

      DIGITAL_RE = /^&#((?:x[a-f0-9]{1,6}|[0-9]{1,7}));/i
      NAMED_RE   = /^&([a-z][a-z0-9]{1,31});/i

      #------------------------------------------------------------------------------
      def self.entity(state, silent)
        pos = state.pos
        max = state.posMax

        return false if charCodeAt(state.src, pos) != 0x26 # &

        return false if pos + 1 >= max

        ch = charCodeAt(state.src, pos + 1)

        if ch == 0x23     # '#'
          match = state.src[pos..-1].match(DIGITAL_RE)
          if match
            if !silent
              code = match[1][0].downcase == 'x' ? match[1][1..-1].to_i(16) : match[1].to_i

              token         = state.push('text_special', '', 0)
              token.content = isValidEntityCode(code) ? fromCodePoint(code) : fromCodePoint(0xFFFD)
              token.markup  = match[0]
              token.info    = 'entity'
            end
            state.pos += match[0].length
            return true
          end
        else
          match = state.src[pos..-1].match(NAMED_RE)
          if match
            if MarkdownIt::HTMLEntities::MAPPINGS[match[1]]
              if !silent
                token          = state.push('text_special', '', 0)
                token.content += fromCodePoint(MarkdownIt::HTMLEntities::MAPPINGS[match[1]])
                token.markup  = match[0]
                token.info    = 'entity'
              end
              state.pos += match[0].length
              return true
            end
          end
        end

        return false
      end
    end
  end
end
