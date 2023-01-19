# internal
# class Core
#
# Top-level rules executor. Glues block/inline parsers and does intermediate
# transformations.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserCore

    attr_accessor   :ruler

    RULES = [
      [ 'normalize',      lambda { |state| RulesCore::Normalize.normalize(state) }      ],
      [ 'block',          lambda { |state| RulesCore::Block.block(state) }              ],
      [ 'inline',         lambda { |state| RulesCore::Inline.inline(state) }            ],
      [ 'linkify',        lambda { |state| RulesCore::Linkify.linkify(state) }          ],
      [ 'replacements',   lambda { |state| RulesCore::Replacements.replace(state) }     ],
      [ 'smartquotes',    lambda { |state| RulesCore::Smartquotes.smartquotes(state) }  ],
      # `text_join` finds `text_special` tokens (for escape sequences)
      # and joins them with the rest of the text
      [ 'text_join',      lambda { |state| RulesCore::TextJoin.text_join(state) }       ],
    ]


    # new Core()
    #------------------------------------------------------------------------------
    def initialize
      # Core#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of core rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(rule[0], rule[1])
      end
    end

    # Core.process(state)
    #
    # Executes core chain rules.
    #------------------------------------------------------------------------------
    def process(state)
      rules = @ruler.getRules('')
      rules.each do |rule|
        rule.call(state)
      end
    end
  end
end
