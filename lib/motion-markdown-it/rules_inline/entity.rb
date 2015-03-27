# Process html entity - &#123;, &#xAF;, &quot;, ...
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Entity
      extend Common::Utils
      
      DIGITAL_RE = /^&#((?:x[a-f0-9]{1,8}|[0-9]{1,8}));/i
      NAMED_RE   = /^&([a-z][a-z0-9]{1,31});/i


      #------------------------------------------------------------------------------
      def self.entity(state, silent)
        pos = state.pos
        max = state.posMax

        return false if state.src.charCodeAt(pos) != 0x26    # &

        if pos + 1 < max
          ch = state.src.charCodeAt(pos + 1)

          if ch == 0x23     # '#'
            match = state.src.slice_to_end(pos).match(DIGITAL_RE)
            if match
              if !silent
                code = match[1][0].downcase == 'x' ? match[1].slice_to_end(1).to_i(16) : match[1].to_i
                state.pending += isValidEntityCode(code) ? fromCodePoint(code) : fromCodePoint(0xFFFD)
              end
              state.pos += match[0].length
              return true
            end
          else
            match = state.src.slice_to_end(pos).match(NAMED_RE)
            if match
              if HTMLEntities::MAPPINGS[match[1]]
                state.pending += HTMLEntities::MAPPINGS[match[1]].chr(Encoding::UTF_8) if !silent
                state.pos     += match[0].length
                return true
              end
            end
          end
        end

        state.pending += '&' if !silent
        state.pos += 1
        return true
      end

    end
  end
end
