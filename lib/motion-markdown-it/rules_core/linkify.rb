# Replace link-like texts with link nodes.
#
# Currently restricted by `md.validateLink()` to http/https/ftp
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Linkify

      #------------------------------------------------------------------------------
      def self.isLinkOpen(str)
        return !(/^<a[>\s]/i =~ str).nil?
      end
      def self.isLinkClose(str)
        return !(/^<\/a\s*>/i =~ str).nil?
      end

      #------------------------------------------------------------------------------
      def self.linkify(state)
        blockTokens = state.tokens

          return if (!state.md.options[:linkify])

          (0...blockTokens.length).each do |j|
            if (blockTokens[j].type != 'inline' || !state.md.linkify.pretest(blockTokens[j].content))
              next
            end

            tokens = blockTokens[j].children

            htmlLinkLevel = 0

            # We scan from the end, to keep position when new tags added.
            # Use reversed logic in links start/end match
            i = tokens.length - 1
            while i >= 0
              currentToken = tokens[i]

              # Skip content of markdown links
              if (currentToken.type == 'link_close')
                i -= 1
                while (tokens[i].level != currentToken.level && tokens[i].type != 'link_open')
                  i -= 1
                end
                next
              end

              # Skip content of html tag links
              if (currentToken.type == 'html_inline')
                if (isLinkOpen(currentToken.content) && htmlLinkLevel > 0)
                  htmlLinkLevel -= 1
                end
                if (isLinkClose(currentToken.content))
                  htmlLinkLevel -= 1
                end
              end
              next if (htmlLinkLevel > 0)

              if (currentToken.type == 'text' && state.md.linkify =~ currentToken.content)

                text = currentToken.content
                links = state.md.linkify.match(text)

                # Now split string to nodes
                nodes   = []
                level   = currentToken.level
                lastPos = 0
                
                (0...links.length).each do |ln|
                  url = links[ln].url
                  fullUrl = state.md.normalizeLink.call(url)
                  next if (!state.md.validateLink.call(fullUrl))

                  urlText = links[ln].text

                  # Linkifier might send raw hostnames like "example.com", where url
                  # starts with domain name. So we prepend http:// in those cases,
                  # and remove it afterwards.
                  #

# TODO work on this when clearer
puts "Linkify requires work"
                  # if (!links[ln].schema)
                  #   urlText = state.md.normalizeLinkText.call('http://' + urlText).replace(/^http:\/\//, '')
                  # elsif (links[ln].schema == 'mailto:' && !Regexp.new('^mailto:/i') =~ urlText)
                  #   urlText = state.md.normalizeLinkText.call('mailto:' + urlText).replace(/^mailto:/, '');
                  # } else {
                  #   urlText = state.md.normalizeLinkText.call(urlText);
                  # }

                  pos = links[ln].index

                  if (pos > lastPos)
                    token         = Token.new('text', '', 0)
                    token.content = text.slice(lastPos...pos)
                    token.level   = level
                    nodes.push(token)
                  end

                  token         = Token.new('link_open', 'a', 1)
                  token.attrs   = [ [ 'href', fullUrl ] ]
                  token.level   = level
                  level        += 1
                  token.markup  = 'linkify'
                  token.info    = 'auto'
                  nodes.push(token)

                  token         = Token.new('text', '', 0)
                  token.content = urlText
                  token.level   = level
                  nodes.push(token)

                  token         = Token.new('link_close', 'a', -1)
                  level        -= 1
                  token.level   = level
                  token.markup  = 'linkify'
                  token.info    = 'auto'
                  nodes.push(token)

                  lastPos = links[ln].lastIndex
                end
                if (lastPos < text.length)
                  token         = Token.new('text', '', 0)
                  token.content = text.slice_to_end(lastPos)
                  token.level   = level
                  nodes.push(token)
                end

                # replace current node
                blockTokens[j].children = tokens = arrayReplaceAt(tokens, i, nodes)
              end
              i -= 1
            end
          end
      end

    end
  end
end