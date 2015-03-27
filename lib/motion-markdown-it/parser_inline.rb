# internal
# class ParserInline
#
# Tokenizes paragraph content.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserInline
    
    attr_accessor   :ruler
    
    #------------------------------------------------------------------------------
    # Parser rules

    RULES = [
      [ 'text',            lambda { |state, startLine| RulesInline::Text.text(state, startLine) } ],
      [ 'newline',         lambda { |state, startLine| RulesInline::Newline.newline(state, startLine) } ],
      [ 'escape',          lambda { |state, startLine| RulesInline::Escape.escape(state, startLine) } ],
      [ 'backticks',       lambda { |state, startLine| RulesInline::Backticks.backtick(state, startLine) } ],
      [ 'strikethrough',   lambda { |state, startLine| RulesInline::Strikethrough.strikethrough(state, startLine) } ],
      [ 'emphasis',        lambda { |state, startLine| RulesInline::Emphasis.emphasis(state, startLine) } ],
      [ 'link',            lambda { |state, startLine| RulesInline::Link.link(state, startLine) } ],
      [ 'image',           lambda { |state, startLine| RulesInline::Image.image(state, startLine) } ],
      [ 'autolink',        lambda { |state, startLine| RulesInline::Autolink.autolink(state, startLine) } ],
      [ 'html_inline',     lambda { |state, startLine| RulesInline::HtmlInline.html_inline(state, startLine) } ],
      [ 'entity',          lambda { |state, startLine| RulesInline::Entity.entity(state, startLine) } ],
    ]


    #------------------------------------------------------------------------------
    def initialize
      # ParserInline#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of inline rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(rule[0], rule[1])
      end
    end

    # Skip single token by running all rules in validation mode;
    # returns `true` if any rule reported success
    #------------------------------------------------------------------------------
    def skipToken(state)
      pos        = state.pos
      rules      = @ruler.getRules('')
      len        = rules.length
      maxNesting = state.md.options[:maxNesting]
      cache      = state.cache


      if cache[pos] != nil
        state.pos = cache[pos]
        return
      end

      # istanbul ignore else
      if state.level < maxNesting
        0.upto(len -1) do |i|
          if rules[i].call(state, true)
            cache[pos] = state.pos
            return
          end
        end
      end

      state.pos += 1
      cache[pos] = state.pos
    end


    # Generate tokens for input range
    #------------------------------------------------------------------------------
    def tokenize(state)
      rules      = @ruler.getRules('')
      len        = rules.length
      end_pos    = state.posMax
      maxNesting = state.md.options[:maxNesting]

      while state.pos < end_pos
        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.pos`
        # - update `state.tokens`
        # - return true

        ok = false
        if state.level < maxNesting
          0.upto(len - 1) do |i|
            ok = rules[i].call(state, false)
            break if ok
          end
        end

        if ok
          break if state.pos >= end_pos
          next
        end

        state.pending += state.src[state.pos]
        state.pos     += 1
      end

      unless state.pending.empty?
        state.pushPending
      end
    end

    # ParserInline.parse(str, md, env, outTokens)
    #
    # Process input string and push inline tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(str, md, env, outTokens)
      state = RulesInline::StateInline.new(str, md, env, outTokens)

      tokenize(state)
    end

  end
end