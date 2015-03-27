# internal
# class ParserBlock
#
# Block-level tokenizer.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserBlock

    attr_accessor   :ruler
    
    RULES = [
      # First 2 params - rule name & source. Secondary array - list of rules,
      # which can be terminated by this one.
      [ 'code',         lambda { |state, startLine, endLine, silent| RulesBlock::Code.code(state, startLine, endLine, silent) } ],
      [ 'fence',        lambda { |state, startLine, endLine, silent| RulesBlock::Fence.fence(state, startLine, endLine, silent) },      [ 'paragraph', 'reference', 'blockquote', 'list' ] ],
      [ 'blockquote',   lambda { |state, startLine, endLine, silent| RulesBlock::Blockquote.blockquote(state, startLine, endLine, silent) }, [ 'paragraph', 'reference', 'list' ] ],
      [ 'hr',           lambda { |state, startLine, endLine, silent| RulesBlock::Hr.hr(state, startLine, endLine, silent) },         [ 'paragraph', 'reference', 'blockquote', 'list' ] ],
      [ 'list',         lambda { |state, startLine, endLine, silent| RulesBlock::List.list(state, startLine, endLine, silent) },       [ 'paragraph', 'reference', 'blockquote' ] ],
      [ 'reference',    lambda { |state, startLine, endLine, silent| RulesBlock::Reference.reference(state, startLine, endLine, silent) } ],
      [ 'heading',      lambda { |state, startLine, endLine, silent| RulesBlock::Heading.heading(state, startLine, endLine, silent) },    [ 'paragraph', 'reference', 'blockquote' ] ],
      [ 'lheading',     lambda { |state, startLine, endLine, silent| RulesBlock::Lheading.lheading(state, startLine, endLine, silent) } ],
      [ 'html_block',   lambda { |state, startLine, endLine, silent| RulesBlock::HtmlBlock.html_block(state, startLine, endLine, silent) }, [ 'paragraph', 'reference', 'blockquote' ] ],
      [ 'table',        lambda { |state, startLine, endLine, silent| RulesBlock::Table.table(state, startLine, endLine, silent) },      [ 'paragraph', 'reference' ] ],
      [ 'paragraph',    lambda { |state, startLine, endLine, silent| RulesBlock::Paragraph.paragraph(state, startLine) } ]
    ]


    # new ParserBlock()
    #------------------------------------------------------------------------------
    def initialize
      # ParserBlock#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of block rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(rule[0], rule[1], {alt: (rule[2] || []) })
      end
    end


    # Generate tokens for input range
    #------------------------------------------------------------------------------
    def tokenize(state, startLine, endLine, ignored = false)
      rules         = @ruler.getRules('')
      len           = rules.length
      line          = startLine
      hasEmptyLines = false
      maxNesting    = state.md.options[:maxNesting]
      
      while line < endLine
        state.line = line = state.skipEmptyLines(line)
        break if line >= endLine

        # Termination condition for nested calls.
        # Nested calls currently used for blockquotes & lists
        break if state.tShift[line] < state.blkIndent

        # If nesting level exceeded - skip tail to the end. That's not ordinary
        # situation and we should not care about content.
        if state.level >= maxNesting
          state.line = endLine
          break
        end

        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.line`
        # - update `state.tokens`
        # - return true
        0.upto(len - 1) do |i|
          ok = rules[i].call(state, line, endLine, false)
          break if ok
        end

        # set state.tight iff we had an empty line before current tag
        # i.e. latest empty line should not count
        state.tight = !hasEmptyLines

        # paragraph might "eat" one newline after it in nested lists
        if state.isEmpty(state.line - 1)
          hasEmptyLines = true
        end

        line = state.line

        if line < endLine && state.isEmpty(line)
          hasEmptyLines = true
          line += 1

          # two empty lines should stop the parser in list mode
          break if line < endLine && state.parentType == 'list' && state.isEmpty(line)
          state.line = line
        end
      end
    end

    # ParserBlock.parse(src, md, env, outTokens)
    #
    # Process input string and push block tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(src, md, env, outTokens)

      reutrn [] if !src

      state = RulesBlock::StateBlock.new(src, md, env, outTokens)

      tokenize(state, state.line, state.lineMax)
    end

  end
end