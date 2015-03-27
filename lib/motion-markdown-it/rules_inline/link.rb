# Process [link](<to> "stuff")
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Link
      extend Helpers::ParseLinkDestination
      extend Helpers::ParseLinkLabel
      extend Helpers::ParseLinkTitle
      extend Common::Utils

      #------------------------------------------------------------------------------
      def self.link(state, silent)
        href   = ''
        oldPos = state.pos
        max    = state.posMax
        start  = state.pos

        return false if (state.src.charCodeAt(state.pos) != 0x5B) # [

        labelStart = state.pos + 1
        labelEnd   = parseLinkLabel(state, state.pos, true)

        # parser failed to find ']', so it's not a valid link
        return false if (labelEnd < 0)

        pos = labelEnd + 1
        if (pos < max && state.src.charCodeAt(pos) == 0x28) # (
          #
          # Inline link
          #

          # [link](  <href>  "title"  )
          #        ^^ skipping these spaces
          pos += 1
          while pos < max
            code = state.src.charCodeAt(pos)
            break if (code != 0x20 && code != 0x0A)
            pos += 1
          end
          return false if (pos >= max)

          # [link](  <href>  "title"  )
          #          ^^^^^^ parsing link destination
          start = pos
          res   = parseLinkDestination(state.src, pos, state.posMax)
          if (res[:ok])
            href = state.md.normalizeLink.call(res[:str])
            if (state.md.validateLink.call(href))
              pos = res[:pos]
            else
              href = ''
            end
          end

          # [link](  <href>  "title"  )
          #                ^^ skipping these spaces
          start = pos
          while pos < max
            code = state.src.charCodeAt(pos)
            break if (code != 0x20 && code != 0x0A)
            pos += 1
          end

          # [link](  <href>  "title"  )
          #                  ^^^^^^^ parsing link title
          res = parseLinkTitle(state.src, pos, state.posMax)
          if (pos < max && start != pos && res[:ok])
            title = res[:str]
            pos   = res[:pos]

            # [link](  <href>  "title"  )
            #                         ^^ skipping these spaces
            while pos < max
              code = state.src.charCodeAt(pos)
              break if (code != 0x20 && code != 0x0A)
              pos += 1
            end
          else
            title = ''
          end

          if (pos >= max || state.src.charCodeAt(pos) != 0x29) # )
            state.pos = oldPos
            return false
          end
          pos += 1
        else
          #
          # Link reference
          #
          return false if state.env[:references].nil?

          # [foo]  [bar]
          #      ^^ optional whitespace (can include newlines)
          while pos < max
            code = state.src.charCodeAt(pos);
            break if (code != 0x20 && code != 0x0A)
            pos += 1
          end

          if (pos < max && state.src.charCodeAt(pos) == 0x5B)  # [
            start = pos + 1
            pos   = parseLinkLabel(state, pos)
            if (pos >= 0)
              label = state.src.slice(start...pos)
              pos += 1
            else
              pos = labelEnd + 1
            end
          else
            pos = labelEnd + 1
          end

          # covers label === '' and label === undefined
          # (collapsed reference link and shortcut reference link respectively)
          label = state.src.slice(labelStart...labelEnd) if label.nil? || label.empty?

          ref = state.env[:references][normalizeReference(label)]
          if (!ref)
            state.pos = oldPos
            return false
          end
          href  = ref[:href]
          title = ref[:title]
        end

        #
        # We found the end of the link, and know for a fact it's a valid link;
        # so all that's left to do is to call tokenizer.
        #
        if (!silent)
          state.pos    = labelStart
          state.posMax = labelEnd

          token        = state.push('link_open', 'a', 1)
          token.attrs  = attrs = [ [ 'href', href ] ]
          unless title.nil? || title.empty?
            attrs.push([ 'title', title ])
          end

          state.md.inline.tokenize(state)

          token        = state.push('link_close', 'a', -1)
        end

        state.pos     = pos
        state.posMax  = max
        return true
      end

    end
  end
end