# Process autolinks '<protocol:...>'
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Autolink
      extend Common::Utils

      EMAIL_RE    = /^([a-zA-Z0-9.!#$\%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)$/
      AUTOLINK_RE = /^([a-zA-Z][a-zA-Z0-9+.\-]{1,31}):([^<>\x00-\x20]*)$/

      #------------------------------------------------------------------------------
      def self.autolink(state, silent)
        pos = state.pos

        return false if (charCodeAt(state.src, pos) != 0x3C)  # <

        start = state.pos
        max = state.posMax

        loop do
          return false if ((pos += 1) >= max)

          ch = charCodeAt(state.src, pos)

          return false if (ch == 0x3C) # <
          break if (ch == 0x3E) # >
        end

        url = state.src.slice((start + 1)...pos)

        if (AUTOLINK_RE =~ url)
          fullUrl = state.md.normalizeLink.call(url)
          return false if (!state.md.validateLink.call(fullUrl))

          if (!silent)
            token         = state.push('link_open', 'a', 1)
            token.attrs   = [ [ 'href', fullUrl ] ]
            token.markup  = 'autolink'
            token.info    = 'auto'

            token         = state.push('text', '', 0)
            token.content = state.md.normalizeLinkText.call(url)

            token         = state.push('link_close', 'a', -1)
            token.markup  = 'autolink'
            token.info    = 'auto'
          end

          state.pos += url.length + 2
          return true
        end

        if (EMAIL_RE =~ url)
          fullUrl = state.md.normalizeLink.call('mailto:' + url)
          return false if (!state.md.validateLink.call(fullUrl))

          if (!silent)
            token         = state.push('link_open', 'a', 1)
            token.attrs   = [ [ 'href', fullUrl ] ]
            token.markup  = 'autolink'
            token.info    = 'auto'

            token         = state.push('text', '', 0)
            token.content = state.md.normalizeLinkText.call(url)

            token         = state.push('link_close', 'a', -1)
            token.markup  = 'autolink'
            token.info    = 'auto'
          end

          state.pos += url.length + 2
          return true
        end

        return false
      end

    end
  end
end
