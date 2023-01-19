# Process links like https://example.org/
module MarkdownIt
  module RulesInline
    class Linkify
      extend Common::Utils

      # RFC3986: scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
      SCHEME_RE = /(?:^|[^a-z0-9.+-])([a-z][a-z0-9.+-]*)$/i

      #------------------------------------------------------------------------------
      def self.linkify(state, silent)
        return false if (!state.md.options[:linkify])
        return false if (state.linkLevel > 0)
      
        pos = state.pos
        max = state.posMax

        return false if (pos + 3 > max)
        return false if (charCodeAt(state.src, pos) != 0x3A) # :
        return false if (charCodeAt(state.src, pos + 1) != 0x2F) # /
        return false if (charCodeAt(state.src, pos + 2) != 0x2F) # /
      
        match = state.pending.match(SCHEME_RE)
        return false if (!match)
      
        proto = match[1]
      
        link = state.md.linkify.matchAtStart(state.src.slice((pos - proto.length)..-1))
        return false if (!link)
      
        url = link.url
      
        # disallow '*' at the end of the link (conflicts with emphasis)
        url = url.sub(/\*+$/, '')
      
        fullUrl = state.md.normalizeLink.call(url)
        return false if (!state.md.validateLink.call(fullUrl))
      
        if (!silent)
          state.pending = state.pending[0...-proto.length]
      
          token         = state.push('link_open', 'a', 1)
          token.attrs   = [ [ 'href', fullUrl ] ]
          token.markup  = 'linkify'
          token.info    = 'auto'
      
          token         = state.push('text', '', 0)
          token.content = state.md.normalizeLinkText.call(url)
      
          token         = state.push('link_close', 'a', -1)
          token.markup  = 'linkify'
          token.info    = 'auto'
        end
      
        state.pos += url.length - proto.length
        return true
      end
    end
  end
end
