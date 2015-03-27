# Core state object
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class StateCore

      attr_accessor   :src, :env, :tokens, :inlineMode, :md

      #------------------------------------------------------------------------------
      def initialize(src, md, env)
        @src        = src
        @env        = env
        @tokens     = []
        @inlineMode = false
        @md         = md    # link to parser instance
      end

    end
  end
end