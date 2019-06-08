# Skip text characters for text token, place those to pending buffer
# and increment current pos
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Text
      extend Common::Utils

      # Rule to skip pure text
      # '{}$%@~+=:' reserved for extentions

      # !, ", #, $, %, &, ', (, ), *, +, ,, -, ., /, :, ;, <, =, >, ?, @, [, \, ], ^, _, `, {, |, }, or ~

      # !!!! Don't confuse with "Markdown ASCII Punctuation" chars
      # http://spec.commonmark.org/0.15/#ascii-punctuation-character
      #------------------------------------------------------------------------------
      def self.isTerminatorChar(ch)
        case ch
        when 0x0A,    # \n
             0x21,    # !
             0x23,    # #
             0x24,    # $
             0x25,    # %
             0x26,    # &
             0x2A,    # *
             0x2B,    # +
             0x2D,    # -
             0x3A,    # :
             0x3C,    # <
             0x3D,    # =
             0x3E,    # >
             0x40,    # @
             0x5B,    # [
             0x5C,    # \
             0x5D,    # ]
             0x5E,    # ^
             0x5F,    # _
             0x60,    # `
             0x7B,    # {
             0x7D,    # }
             0x7E     # ~
          return true
        else
          return false
        end
      end

      #------------------------------------------------------------------------------
      def self.text(state, silent)
        pos = state.pos

        while pos < state.posMax && !self.isTerminatorChar(charCodeAt(state.src, pos))
          pos += 1
        end

        return false if pos == state.pos

        state.pending += state.src.slice(state.pos...pos) if !silent
        state.pos      = pos
        return true
      end

      # // Alternative implementation, for memory.
      # //
      # // It costs 10% of performance, but allows extend terminators list, if place it
      # // to `ParcerInline` property. Probably, will switch to it sometime, such
      # // flexibility required.
      #
      # /*
      # var TERMINATOR_RE = /[\n!#$%&*+\-:<=>@[\\\]^_`{}~]/;
      #
      # module.exports = function text(state, silent) {
      #   var pos = state.pos,
      #       idx = state.src.slice(pos).search(TERMINATOR_RE);
      #
      #   // first char is terminator -> empty text
      #   if (idx === 0) { return false; }
      #
      #   // no terminator -> text till end of string
      #   if (idx < 0) {
      #     if (!silent) { state.pending += state.src.slice(pos); }
      #     state.pos = state.src.length;
      #     return true;
      #   }
      #
      #   if (!silent) { state.pending += state.src.slice(pos, pos + idx); }
      #
      #   state.pos += idx;
      #
      #   return true;
      # };*/

    end
  end
end