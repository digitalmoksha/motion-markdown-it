# Process autolinks '<protocol:...>'
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Autolink

      EMAIL_RE    = /^<([a-zA-Z0-9.!#$\%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/
      AUTOLINK_RE = /^<([a-zA-Z][a-zA-Z0-9+.\-]{1,31}):([^<>\x00-\x20]*)>/

      #------------------------------------------------------------------------------
      def self.autolink(state, silent)
        pos = state.pos

        return false if (charCodeAt(state.src, pos) != 0x3C)  # <

        tail = state.src[pos..-1]

        return false if !tail.include?('>')

        if (AUTOLINK_RE =~ tail)
          linkMatch = tail.match(AUTOLINK_RE)

          url = linkMatch[0].slice(1...-1)
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

          state.pos += linkMatch[0].length
          return true
        end

        if (EMAIL_RE =~ tail)
          emailMatch = tail.match(EMAIL_RE)

          url = emailMatch[0].slice(1...-1)
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

          state.pos += emailMatch[0].length
          return true
        end

        return false
      end

    end
  end
end
