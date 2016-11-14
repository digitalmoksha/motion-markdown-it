# Regexps to match html elements
#------------------------------------------------------------------------------
module MarkdownIt
  module Common
    module HtmlRe
      ATTR_NAME     = '[a-zA-Z_:][a-zA-Z0-9:._-]*'

      UNQUOTED      = '[^"\'=<>`\\x00-\\x20]+'
      SINGLE_QUOTED = "'[^']*'"
      DOUBLE_QUOTED = '"[^"]*"';

      ATTR_VALUE    = '(?:' + UNQUOTED + '|' + SINGLE_QUOTED + '|' + DOUBLE_QUOTED + ')'
                  
      ATTRIBUTE     = '(?:\\s+' + ATTR_NAME + '(?:\\s*=\\s*' + ATTR_VALUE + ')?)'
                  
      OPEN_TAG      = '<[A-Za-z][A-Za-z0-9\\-]*' + ATTRIBUTE + '*\\s*\\/?>'
                  
      CLOSE_TAG     = '<\\/[A-Za-z][A-Za-z0-9\\-]*\\s*>'
      COMMENT       = '<!---->|<!--(?:-?[^>-])(?:-?[^-])*-->'
      PROCESSING    = '<[?].*?[?]>'
      DECLARATION   = '<![A-Z]+\\s+[^>]*>'
      CDATA         = '<!\\[CDATA\\[[\\s\\S]*?\\]\\]>'

      HTML_TAG_RE     = Regexp.new('^(?:' + OPEN_TAG + '|' + CLOSE_TAG + '|' + COMMENT +
                            '|' + PROCESSING + '|' + DECLARATION + '|' + CDATA + ')')

      HTML_OPEN_CLOSE_TAG_RE = Regexp.new('^(?:' + OPEN_TAG + '|' + CLOSE_TAG + ')')
    end
  end
end