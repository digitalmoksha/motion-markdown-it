# Process [link](<to> "stuff")
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Link
      extend Common::Utils

      #------------------------------------------------------------------------------
      def self.link(state, silent)
        href            = ''
        oldPos          = state.pos
        max             = state.posMax
        start           = state.pos
        parseReference  = true

        return false if (charCodeAt(state.src, state.pos) != 0x5B) # [

        labelStart = state.pos + 1
        labelEnd   = state.md.helpers.parseLinkLabel(state, state.pos, true)

        # parser failed to find ']', so it's not a valid link
        return false if (labelEnd < 0)

        pos = labelEnd + 1
        if (pos < max && charCodeAt(state.src, pos) == 0x28) # (
          #
          # Inline link
          #

          # might have found a valid shortcut link, disable reference parsing
          parseReference = false

          # [link](  <href>  "title"  )
          #        ^^ skipping these spaces
          pos += 1
          while pos < max
            code = charCodeAt(state.src, pos)
            break if (!isSpace(code) && code != 0x0A)
            pos += 1
          end
          return false if (pos >= max)

          # [link](  <href>  "title"  )
          #          ^^^^^^ parsing link destination
          start = pos
          res   = state.md.helpers.parseLinkDestination(state.src, pos, state.posMax)
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
            code = charCodeAt(state.src, pos)
            break if (!isSpace(code) && code != 0x0A)
            pos += 1
          end

          # [link](  <href>  "title"  )
          #                  ^^^^^^^ parsing link title
          res = state.md.helpers.parseLinkTitle(state.src, pos, state.posMax)
          if (pos < max && start != pos && res[:ok])
            title = res[:str]
            pos   = res[:pos]

            # [link](  <href>  "title"  )
            #                         ^^ skipping these spaces
            while pos < max
              code = charCodeAt(state.src, pos)
              break if (!isSpace(code) && code != 0x0A)
              pos += 1
            end
          else
            title = ''
          end

          if (pos >= max || charCodeAt(state.src, pos) != 0x29) # )
            # parsing a valid shortcut link failed, fallback to reference
            parseReference = true
          end
          pos += 1
        end

        if parseReference
          #
          # Link reference
          #
          return false if state.env[:references].nil?

          if (pos < max && charCodeAt(state.src, pos) == 0x5B)  # [
            start = pos + 1
            pos   = state.md.helpers.parseLinkLabel(state, pos)
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