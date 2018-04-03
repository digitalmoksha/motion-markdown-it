module MarkdownIt
  module Helpers
    class HelperWrapper
      include ParseLinkDestination
      include ParseLinkLabel
      include ParseLinkTitle
    end
  end
end