# "Zero" preset, with nothing enabled. Useful for manual configuring of simple
# modes. For example, to parse bold/italic only.

module MarkdownIt
  module Presets
    class Zero
      def self.options
        {
          options: {
            html:         false,        # Enable HTML tags in source
            xhtmlOut:     false,        # Use '/' to close single tags (<br />)
            breaks:       false,        # Convert '\n' in paragraphs into <br>
            langPrefix:   'language-',  # CSS language prefix for fenced blocks
            linkify:      false,        # autoconvert URL-like texts to links

            # Enable some language-neutral replacements + quotes beautification
            typographer:  false,

            # Double + single quotes replacement pairs, when typographer enabled,
            # and smartquotes on. Set doubles to '«»' for Russian, '„“' for German.
            quotes: "\u201c\u201d\u2018\u2019", # “”‘’

            # Highlighter function. Should return escaped HTML,
            # or '' if input not changed
            #
            # function (/*str, lang*/) { return ''; }
            #
            highlight: nil,

            maxNesting:   20            # Internal protection, recursion limit
          },

          components: {

            core: {
              rules: [
                'normalize',
                'block',
                'inline'
              ]
            },

            block: {
              rules: [
                'paragraph'
              ]
            },

            inline: {
              rules: [
                'text'
              ]
            }
          }
        }
      end
    end
  end
end