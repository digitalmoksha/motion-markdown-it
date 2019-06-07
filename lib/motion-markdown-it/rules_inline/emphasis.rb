# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Emphasis
      extend MarkdownIt::Common::Utils

      # Insert each marker as a separate text token, and add it to delimiter list
      #
      def self.tokenize(state, silent)
        start   = state.pos
        marker  = charCodeAt(state.src, start)

        return false if silent

        return false if (marker != 0x5F && marker != 0x2A) #  _ and *

        scanned = state.scanDelims(state.pos, marker == 0x2A)

        0.upto(scanned[:length] - 1) do |i|
          token         = state.push('text', '', 0)
          token.content = fromCodePoint(marker)

          state.delimiters.push({
            # Char code of the starting marker (number).
            #
            marker: marker,

            # Total length of these series of delimiters.
            #
            length: scanned[:length],

            # An amount of characters before this one that's equivalent to
            # current one. In plain English: if this delimiter does not open
            # an emphasis, neither do previous `jump` characters.
            #
            # Used to skip sequences like "*****" in one step, for 1st asterisk
            # value will be 0, for 2nd it's 1 and so on.
            #
            jump:   i,

            # A position of the token this delimiter corresponds to.
            #
            token:  state.tokens.length - 1,

            # Token level.
            #
            level:  state.level,

            # If this delimiter is matched as a valid opener, `end` will be
            # equal to its position, otherwise it's `-1`.
            #
            end:    -1,

            # Boolean flags that determine if this delimiter could open or close
            # an emphasis.
            #
            open:   scanned[:can_open],
            close:  scanned[:can_close]
          })
        end

        state.pos += scanned[:length]

        return true
      end


      # Walk through delimiter list and replace text tokens with tags
      #
      def self.postProcess(state)
        delimiters = state.delimiters
        max = state.delimiters.length

        i = max - 1
        while i >= 0
          startDelim = delimiters[i]

          (i -= 1) and next if startDelim[:marker] != 0x5F && startDelim[:marker] != 0x2A #  _ and *

          # Process only opening markers
          (i -= 1) and next if startDelim[:end] == -1

          endDelim = delimiters[startDelim[:end]]

          # If the previous delimiter has the same marker and is adjacent to this one,
          # merge those into one strong delimiter.
          #
          # `<em><em>whatever</em></em>` -> `<strong>whatever</strong>`
          #
          isStrong = i > 0 &&
                     delimiters[i - 1][:end] == startDelim[:end] + 1 &&
                     delimiters[i - 1][:token] == startDelim[:token] - 1 &&
                     delimiters[startDelim[:end] + 1][:token] == endDelim[:token] + 1 &&
                     delimiters[i - 1][:marker] == startDelim[:marker]

          ch = fromCodePoint(startDelim[:marker])

          token         = state.tokens[startDelim[:token]]
          token.type    = isStrong ? 'strong_open' : 'em_open'
          token.tag     = isStrong ? 'strong' : 'em'
          token.nesting = 1
          token.markup  = isStrong ? ch + ch : ch
          token.content = ''

          token         = state.tokens[endDelim[:token]]
          token.type    = isStrong ? 'strong_close' : 'em_close'
          token.tag     = isStrong ? 'strong' : 'em'
          token.nesting = -1
          token.markup  = isStrong ? ch + ch : ch
          token.content = ''

          if isStrong
            state.tokens[delimiters[i - 1][:token]].content = ''
            state.tokens[delimiters[startDelim[:end] + 1][:token]].content = ''
            i -= 1
          end

          i -= 1
        end
      end
    end
  end
end
