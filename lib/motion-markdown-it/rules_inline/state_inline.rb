# Inline parser state
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class StateInline

      attr_accessor   :src, :env, :md, :tokens, :pos, :posMax, :level
      attr_accessor   :pending, :pendingLevel, :cache

      #------------------------------------------------------------------------------
      def initialize(src, md, env, outTokens)
        @src          = src
        @env          = env
        @md           = md
        @tokens       = outTokens

        @pos          = 0
        @posMax       = @src.length
        @level        = 0
        @pending      = ''
        @pendingLevel = 0

        @cache        = {}      # Stores { start: end } pairs. Useful for backtrack
                                # optimization of pairs parse (emphasis, strikes).
      end


      # Flush pending text
      #------------------------------------------------------------------------------
      def pushPending
        token         = Token.new('text', '', 0)
        token.content = @pending
        token.level   = @pendingLevel
        @tokens.push(token)
        @pending      = ''
        return token
      end

      # Push new token to "stream".
      # If pending text exists - flush it as text token
      #------------------------------------------------------------------------------
      def push(type, tag, nesting)
        pushPending unless @pending.empty?

        token       = Token.new(type, tag, nesting);
        @level     -= 1 if nesting < 0
        token.level = @level
        @level     += 1 if nesting > 0

        @pendingLevel = @level
        @tokens.push(token)
        return token
      end

    end
  end
end