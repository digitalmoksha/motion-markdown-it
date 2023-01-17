# class Renderer
#
# Generates HTML from parsed token stream. Each instance has independent
# copy of rules. Those can be rewritten with ease. Also, you can add new
# rules if you create plugin and adds new token types.
#------------------------------------------------------------------------------
module MarkdownIt
  class Renderer
    include MarkdownIt::Common::Utils
    extend  MarkdownIt::Common::Utils

    attr_accessor   :rules

    # Default Rules
    #------------------------------------------------------------------------------
    def self.code_inline(tokens, idx, options, env, renderer)
      token = tokens[idx]

      return '<code' + renderer.renderAttrs(token) + '>' +
             escapeHtml(tokens[idx].content) +
             '</code>'
    end

    #------------------------------------------------------------------------------
    def self.code_block(tokens, idx, options, env, renderer)
      token = tokens[idx]

      return  '<pre' + renderer.renderAttrs(token) + '><code>' +
              escapeHtml(tokens[idx].content) +
              "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def self.fence(tokens, idx, options, env, renderer)
      token     = tokens[idx]
      info      = token.info ? unescapeAll(token.info).strip : ''
      langName  = ''
      langAttrs = ''

      if !info.empty?
        arr = info.split(/\s+/)
        langName = arr[0]
        langAttrs = arr[1..-1].join(' ')
      end

      if options[:highlight]
        highlighted = options[:highlight].call(token.content, langName, langAttrs) || escapeHtml(token.content)
      else
        highlighted = escapeHtml(token.content)
      end

      if highlighted.start_with?('<pre')
        return highlighted + "\n"
      end

      # If language exists, inject class gently, without modifying original token.
      # May be, one day we will add .deepClone() for token and simplify this part, but
      # now we prefer to keep things local.
      if !info.empty?
        i        = token.attrIndex('class')
        tmpAttrs = token.attrs ? token.attrs.dup : []

        if i < 0
          tmpAttrs.push([ 'class', options[:langPrefix] + langName ])
        else
          tmpAttrs[i] = tmpAttrs[i].slice(0..-1)
          tmpAttrs[i][1] += ' ' + options[:langPrefix] + langName
        end

        # Fake token just to render attributes
        tmpToken       = Token.new(nil, nil, nil)
        tmpToken.attrs = tmpAttrs

        return  '<pre><code' + renderer.renderAttrs(tmpToken) + '>' +
                highlighted +
                "</code></pre>\n"
      end

      return '<pre><code' + renderer.renderAttrs(token) + '>' + highlighted + "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def self.image(tokens, idx, options, env, renderer)
      token = tokens[idx]

      # "alt" attr MUST be set, even if empty. Because it's mandatory and
      # should be placed on proper position for tests.
      #
      # Replace content with actual value

      token.attrs[token.attrIndex('alt')][1] = renderer.renderInlineAsText(token.children, options, env)

      return renderer.renderToken(tokens, idx, options);
    end

    #------------------------------------------------------------------------------
    def self.hardbreak(tokens, idx, options)
      return options[:xhtmlOut] ? "<br />\n" : "<br>\n"
    end
    def self.softbreak(tokens, idx, options)
      return options[:breaks] ? (options[:xhtmlOut] ? "<br />\n" : "<br>\n") : "\n"
    end

    #------------------------------------------------------------------------------
    def self.text(tokens, idx)
      return escapeHtml(tokens[idx].content)
    end

    #------------------------------------------------------------------------------
    def self.html_block(tokens, idx)
      return tokens[idx].content
    end
    def self.html_inline(tokens, idx)
      return tokens[idx].content
    end


    # new Renderer()
    #
    # Creates new [[Renderer]] instance and fill [[Renderer#rules]] with defaults.
    #------------------------------------------------------------------------------
    def initialize
      @default_rules = {
        'code_inline' => lambda {|tokens, idx, options, env, renderer| Renderer.code_inline(tokens, idx, options, env, renderer)},
        'code_block'  => lambda {|tokens, idx, options, env, renderer| Renderer.code_block(tokens, idx, options, env, renderer)},
        'fence'       => lambda {|tokens, idx, options, env, renderer| Renderer.fence(tokens, idx, options, env, renderer)},
        'image'       => lambda {|tokens, idx, options, env, renderer| Renderer.image(tokens, idx, options, env, renderer)},
        'hardbreak'   => lambda {|tokens, idx, options, env, renderer| Renderer.hardbreak(tokens, idx, options)},
        'softbreak'   => lambda {|tokens, idx, options, env, renderer| Renderer.softbreak(tokens, idx, options)},
        'text'        => lambda {|tokens, idx, options, env, renderer| Renderer.text(tokens, idx)},
        'html_block'  => lambda {|tokens, idx, options, env, renderer| Renderer.html_block(tokens, idx)},
        'html_inline' => lambda {|tokens, idx, options, env, renderer| Renderer.html_inline(tokens, idx)}
      }

      # Renderer#rules -> Object
      #
      # Contains render rules for tokens. Can be updated and extended.
      #
      # ##### Example
      #
      # ```javascript
      # var md = require('markdown-it')();
      #
      # md.renderer.rules.strong_open  = function () { return '<b>'; };
      # md.renderer.rules.strong_close = function () { return '</b>'; };
      #
      # var result = md.renderInline(...);
      # ```
      #
      # Each rule is called as independet static function with fixed signature:
      #
      # ```javascript
      # function my_token_render(tokens, idx, options, env, renderer) {
      #   // ...
      #   return renderedHTML;
      # }
      # ```
      #
      # See [source code](https://github.com/markdown-it/markdown-it/blob/master/lib/renderer.js)
      # for more details and examples.
      @rules = assign({}, @default_rules)
    end


    # Renderer.renderAttrs(token) -> String
    #
    # Render token attributes to string.
    #------------------------------------------------------------------------------
    def renderAttrs(token)
      return '' if !token.attrs

      result = ''
      0.upto(token.attrs.length - 1) do |i|
        result += ' ' + escapeHtml(token.attrs[i][0]) + '="' + escapeHtml(token.attrs[i][1].to_s) + '"'
      end

      return result
    end


    # Renderer.renderToken(tokens, idx, options) -> String
    # - tokens (Array): list of tokens
    # - idx (Numbed): token index to render
    # - options (Object): params of parser instance
    #
    # Default token renderer. Can be overriden by custom function
    # in [[Renderer#rules]].
    #------------------------------------------------------------------------------
    def renderToken(tokens, idx, options, env = nil, renderer = nil)
      result = ''
      needLf = false
      token  = tokens[idx]

      # Tight list paragraphs
      return '' if token.hidden

      # Insert a newline between hidden paragraph and subsequent opening
      # block-level tag.
      #
      # For example, here we should insert a newline before blockquote:
      #  - a
      #    >
      #
      if token.block && token.nesting != -1 && idx && tokens[idx - 1].hidden
        result += "\n"
      end

      # Add token name, e.g. `<img`
      result += (token.nesting == -1 ? '</' : '<') + token.tag

      # Encode attributes, e.g. `<img src="foo"`
      result += renderAttrs(token)

      # Add a slash for self-closing tags, e.g. `<img src="foo" /`
      if token.nesting == 0 && options[:xhtmlOut]
        result += ' /'
      end

      # Check if we need to add a newline after this tag
      if token.block
        needLf = true

        if token.nesting == 1
          if idx + 1 < tokens.length
            nextToken = tokens[idx + 1]

            if nextToken.type == 'inline' || nextToken.hidden
              # Block-level tag containing an inline tag.
              #
              needLf = false

            elsif nextToken.nesting == -1 && nextToken.tag == token.tag
              # Opening tag + closing tag of the same type. E.g. `<li></li>`.
              #
              needLf = false
            end
          end
        end
      end

      result += needLf ? ">\n" : '>'

      return result
    end


    # Renderer.renderInline(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to render
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # The same as [[Renderer.render]], but for single token of `inline` type.
    #------------------------------------------------------------------------------
    def renderInline(tokens, options, env)
      result  = ''
      rules   = @rules

      0.upto(tokens.length - 1) do |i|
        type = tokens[i].type

        if rules[type] != nil
          result += rules[type].call(tokens, i, options, env, self)
        else
          result += renderToken(tokens, i, options)
        end
      end

      return result;
    end


    # internal
    # Renderer.renderInlineAsText(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to render
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # Special kludge for image `alt` attributes to conform CommonMark spec.
    # Don't try to use it! Spec requires to show `alt` content with stripped markup,
    # instead of simple escaping.
    #------------------------------------------------------------------------------
    def renderInlineAsText(tokens, options, env)
      result = ''

      0.upto(tokens.length - 1) do |i|
        if tokens[i].type == 'text'
          result += tokens[i].content
        elsif tokens[i].type == 'image'
          result += renderInlineAsText(tokens[i].children, options, env)
        elsif tokens[i].type == 'softbreak'
          result += "\n"
        end
      end

      return result
    end


    # Renderer.render(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to render
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # Takes token stream and generates HTML. Probably, you will never need to call
    # this method directly.
    #------------------------------------------------------------------------------
    def render(tokens, options, env)
      result = ''
      rules  = @rules

      0.upto(tokens.length - 1) do |i|
        type = tokens[i].type

        if type == 'inline'
          result += renderInline(tokens[i].children, options, env)
        elsif rules[type] != nil
          result += rules[tokens[i].type].call(tokens, i, options, env, self)
        else
          result += renderToken(tokens, i, options)
        end
      end

      return result
    end

  end
end
