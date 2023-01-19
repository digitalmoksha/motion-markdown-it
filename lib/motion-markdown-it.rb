# encoding: utf-8

if defined?(Motion::Project::Config)

  lib_dir_path = File.dirname(File.expand_path(__FILE__))
  Motion::Project::App.setup do |app|
    app.files.unshift(Dir.glob(File.join(lib_dir_path, "motion-markdown-it/**/*.rb")))
  end

  require 'linkify-it-rb'
  require 'mdurl-rb'
  require 'uc.micro-rb'

else

  require 'mdurl-rb'
  require 'uc.micro-rb'
  require 'linkify-it-rb'
  require 'motion-markdown-it/version'
  require 'motion-markdown-it/presets/default'
  require 'motion-markdown-it/presets/zero'
  require 'motion-markdown-it/presets/commonmark'
  require 'motion-markdown-it/common/entities'
  require 'motion-markdown-it/common/utils'
  require 'motion-markdown-it/common/html_blocks'
  require 'motion-markdown-it/common/html_re'
  require 'motion-markdown-it/common/simpleidn'
  require 'motion-markdown-it/helpers/parse_link_destination'
  require 'motion-markdown-it/helpers/parse_link_label'
  require 'motion-markdown-it/helpers/parse_link_title'
  require 'motion-markdown-it/helpers/helper_wrapper'
  require 'motion-markdown-it/parser_inline'
  require 'motion-markdown-it/parser_block'
  require 'motion-markdown-it/parser_core'
  require 'motion-markdown-it/renderer'
  require 'motion-markdown-it/rules_core/block'
  require 'motion-markdown-it/rules_core/inline'
  require 'motion-markdown-it/rules_core/linkify'
  require 'motion-markdown-it/rules_core/normalize'
  require 'motion-markdown-it/rules_core/replacements'
  require 'motion-markdown-it/rules_core/smartquotes'
  require 'motion-markdown-it/rules_core/state_core'
  require 'motion-markdown-it/rules_core/text_join'
  require 'motion-markdown-it/rules_block/blockquote'
  require 'motion-markdown-it/rules_block/code'
  require 'motion-markdown-it/rules_block/fence'
  require 'motion-markdown-it/rules_block/heading'
  require 'motion-markdown-it/rules_block/hr'
  require 'motion-markdown-it/rules_block/html_block'
  require 'motion-markdown-it/rules_block/lheading'
  require 'motion-markdown-it/rules_block/list'
  require 'motion-markdown-it/rules_block/paragraph'
  require 'motion-markdown-it/rules_block/reference'
  require 'motion-markdown-it/rules_block/state_block'
  require 'motion-markdown-it/rules_block/table'
  require 'motion-markdown-it/rules_inline/autolink'
  require 'motion-markdown-it/rules_inline/backticks'
  require 'motion-markdown-it/rules_inline/balance_pairs'
  require 'motion-markdown-it/rules_inline/emphasis'
  require 'motion-markdown-it/rules_inline/entity'
  require 'motion-markdown-it/rules_inline/escape'
  require 'motion-markdown-it/rules_inline/fragments_join'
  require 'motion-markdown-it/rules_inline/html_inline'
  require 'motion-markdown-it/rules_inline/image'
  require 'motion-markdown-it/rules_inline/link'
  require 'motion-markdown-it/rules_inline/linkify'
  require 'motion-markdown-it/rules_inline/newline'
  require 'motion-markdown-it/rules_inline/state_inline'
  require 'motion-markdown-it/rules_inline/strikethrough'
  require 'motion-markdown-it/rules_inline/text'

  require 'motion-markdown-it/ruler'
  require 'motion-markdown-it/token'
  require 'motion-markdown-it/index'

end
