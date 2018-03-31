# Main parser class
#------------------------------------------------------------------------------

CONFIG = {
  default:    MarkdownIt::Presets::Default.options,
  zero:       MarkdownIt::Presets::Zero.options,
  commonmark: MarkdownIt::Presets::Commonmark.options
}

#------------------------------------------------------------------------------
# This validator can prohibit more than really needed to prevent XSS. It's a
# tradeoff to keep code simple and to be secure by default.
#
# If you need different setup - override validator method as you wish. Or
# replace it with dummy function and use external sanitizer.

BAD_PROTO_RE = /^(vbscript|javascript|file|data):/
GOOD_DATA_RE = /^data:image\/(gif|png|jpeg|webp);/

VALIDATE_LINK = lambda do |url|
  # url should be normalized at this point, and existing entities are decoded
  #
  str = url.strip.downcase

  return !!(BAD_PROTO_RE =~ str) ? (!!(GOOD_DATA_RE =~ str) ? true : false) : true
end

RECODE_HOSTNAME_FOR = [ 'http:', 'https:', 'mailto:' ]

# mdurl comes from https://github.com/markdown-it/mdurl
NORMALIZE_LINK = lambda do |url|
  parsed = MDUrl::Url.urlParse(url, true)
  if parsed.hostname
    # Encode hostnames in urls like:
    # `http://host/`, `https://host/`, `mailto:user@host`, `//host/`
    #
    # We don't encode unknown schemas, because it's likely that we encode
    # something we shouldn't (e.g. `skype:name` treated as `skype:host`)
    if !parsed.protocol || RECODE_HOSTNAME_FOR.include?(parsed.protocol)
      begin
        trailing_dot    = parsed.hostname[-1] == '.'
        parsed.hostname = SimpleIDN.to_ascii(parsed.hostname)
        parsed.hostname << '.' if trailing_dot
      rescue
        # then use what we already have
      end
    end
  end

  return MDUrl::Encode.encode(MDUrl::Format.format(parsed))
end

NORMALIZE_LINK_TEXT = lambda do |url|
  parsed = MDUrl::Url.urlParse(url, true)
  if parsed.hostname
    # Encode hostnames in urls like:
    # `http://host/`, `https://host/`, `mailto:user@host`, `//host/`
    #
    # We don't encode unknown schemas, because it's likely that we encode
    # something we shouldn't (e.g. `skype:name` treated as `skype:host`)
    if !parsed.protocol || RECODE_HOSTNAME_FOR.include?(parsed.protocol)
      begin
        trailing_dot    = parsed.hostname[-1] == '.'
        parsed.hostname = SimpleIDN.to_unicode(parsed.hostname)
        parsed.hostname << '.' if trailing_dot
      rescue
        # then use what we already have
      end
    end
  end

  return MDUrl::Decode.decode(MDUrl::Format.format(parsed))
end


#------------------------------------------------------------------------------
# class MarkdownIt
#
# Main parser/renderer class.
#
# ##### Usage
#
# ```javascript
# // node.js, "classic" way:
# var MarkdownIt = require('markdown-it'),
#     md = new MarkdownIt();
# var result = md.render('# markdown-it rulezz!');
#
# // node.js, the same, but with sugar:
# var md = require('markdown-it')();
# var result = md.render('# markdown-it rulezz!');
#
# // browser without AMD, added to "window" on script load
# // Note, there are no dash.
# var md = window.markdownit();
# var result = md.render('# markdown-it rulezz!');
# ```
#
# Single line rendering, without paragraph wrap:
#
# ```javascript
# var md = require('markdown-it')();
# var result = md.renderInline('__markdown-it__ rulezz!');
# ```
#------------------------------------------------------------------------------
module MarkdownIt
  class Parser
    include MarkdownIt::Common::Utils

    attr_accessor   :inline
    attr_accessor   :block
    attr_accessor   :core
    attr_accessor   :renderer
    attr_accessor   :options
    attr_accessor   :validateLink
    attr_accessor   :normalizeLink
    attr_accessor   :normalizeLinkText
    attr_accessor   :linkify

    # new MarkdownIt([presetName, options])
    # - presetName (String): optional, `commonmark` / `zero`
    # - options (Object)
    #
    # Creates parser instanse with given config. Can be called without `new`.
    #
    # ##### presetName
    #
    # MarkdownIt provides named presets as a convenience to quickly
    # enable/disable active syntax rules and options for common use cases.
    #
    # - ["commonmark"](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/commonmark.js) -
    #   configures parser to strict [CommonMark](http://commonmark.org/) mode.
    # - [default](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/default.js) -
    #   similar to GFM, used when no preset name given. Enables all available rules,
    #   but still without html, typographer & autolinker.
    # - ["zero"](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/zero.js) -
    #   all rules disabled. Useful to quickly setup your config via `.enable()`.
    #   For example, when you need only `bold` and `italic` markup and nothing else.
    #
    # ##### options:
    #
    # - __html__ - `false`. Set `true` to enable HTML tags in source. Be careful!
    #   That's not safe! You may need external sanitizer to protect output from XSS.
    #   It's better to extend features via plugins, instead of enabling HTML.
    # - __xhtmlOut__ - `false`. Set `true` to add '/' when closing single tags
    #   (`<br />`). This is needed only for full CommonMark compatibility. In real
    #   world you will need HTML output.
    # - __breaks__ - `false`. Set `true` to convert `\n` in paragraphs into `<br>`.
    # - __langPrefix__ - `language-`. CSS language class prefix for fenced blocks.
    #   Can be useful for external highlighters.
    # - __linkify__ - `false`. Set `true` to autoconvert URL-like text to links.
    # - __typographer__  - `false`. Set `true` to enable [some language-neutral
    #   replacement](https://github.com/markdown-it/markdown-it/blob/master/lib/rules_core/replacements.js) +
    #   quotes beautification (smartquotes).
    # - __quotes__ - `“”‘’`, String or Array. Double + single quotes replacement
    #   pairs, when typographer enabled and smartquotes on. For example, you can
    #   use `'«»„“'` for Russian, `'„“‚‘'` for German, and
    #   `['«\xA0', '\xA0»', '‹\xA0', '\xA0›']` for French (including nbsp).
    # - __highlight__ - `nil`. Highlighter function for fenced code blocks.
    #   Highlighter `function (str, lang)` should return escaped HTML. It can also
    #   return nil if the source was not changed and should be escaped
    #   externaly. If result starts with <pre... internal wrapper is skipped.
    #
    # ##### Example
    #
    # ```javascript
    # // commonmark mode
    # var md = require('markdown-it')('commonmark');
    #
    # // default mode
    # var md = require('markdown-it')();
    #
    # // enable everything
    # var md = require('markdown-it')({
    #   html: true,
    #   linkify: true,
    #   typographer: true
    # });
    # ```
    #
    # ##### Syntax highlighting
    #
    # ```js
    # var hljs = require('highlight.js') // https://highlightjs.org/
    #
    # var md = require('markdown-it')({
    #   highlight: function (str, lang) {
    #     if (lang && hljs.getLanguage(lang)) {
    #       try {
    #         return hljs.highlight(lang, str).value;
    #       } catch (__) {}
    #     }
    #
    #     return ''; // use external default escaping
    #   }
    # });
    # ```
    #
    # Or with full wrapper override (if you need assign class to <pre>):
    #
    # ```javascript
    # var hljs = require('highlight.js') // https://highlightjs.org/
    #
    # // Actual default values
    # var md = require('markdown-it')({
    #   highlight: function (str, lang) {
    #     if (lang && hljs.getLanguage(lang)) {
    #       try {
    #         return '<pre class="hljs"><code>' +
    #                hljs.highlight(lang, str).value +
    #                '</code></pre>';
    #       } catch (__) {}
    #     }
    #
    #     return '<pre class="hljs"><code>' + md.utils.esccapeHtml(str) + '</code></pre>';
    #   }
    # });
    # ```
    #-----------------------------------------------------------------------------
    def initialize(presetName = :default, options = {})
      if options.empty?
        if presetName.is_a? Hash
          options     = presetName
          presetName  = :default
        end
      end

      # MarkdownIt#inline -> ParserInline
      #
      # Instance of [[ParserInline]]. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @inline = ParserInline.new

      # MarkdownIt#block -> ParserBlock
      #
      # Instance of [[ParserBlock]]. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @block = ParserBlock.new

      # MarkdownIt#core -> Core
      #
      # Instance of [[Core]] chain executor. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @core = ParserCore.new

      # MarkdownIt#renderer -> Renderer
      #
      # Instance of [[Renderer]]. Use it to modify output look. Or to add rendering
      # rules for new token types, generated by plugins.
      #
      # ##### Example
      #
      # ```javascript
      # var md = require('markdown-it')();
      #
      # function myToken(tokens, idx, options, env, self) {
      #   //...
      #   return result;
      # };
      #
      # md.renderer.rules['my_token'] = myToken
      # ```
      #
      # See [[Renderer]] docs and [source code](https://github.com/markdown-it/markdown-it/blob/master/lib/renderer.js).
      @renderer = Renderer.new

      # MarkdownIt#linkify -> LinkifyIt
      #
      # [linkify-it](https://github.com/markdown-it/linkify-it) instance.
      # Used by [linkify](https://github.com/markdown-it/markdown-it/blob/master/lib/rules_core/linkify.js)
      # rule.
      @linkify = ::Linkify.new

      # MarkdownIt#validateLink(url) -> Boolean
      #
      # Link validation function. CommonMark allows too much in links. By default
      # we disable `javascript:`, `vbscript:`, `file:` schemas, and almost all `data:...` schemas
      # except some embedded image types.
      #
      # You can change this behaviour:
      #
      # ```javascript
      # var md = require('markdown-it')();
      # // enable everything
      # md.validateLink = function () { return true; }
      # ```
      @validateLink = VALIDATE_LINK

      # MarkdownIt#normalizeLink(url) -> String
      #
      # Function used to encode link url to a machine-readable format,
      # which includes url-encoding, punycode, etc.
      @normalizeLink = NORMALIZE_LINK

      # MarkdownIt#normalizeLinkText(url) -> String
      #
      # Function used to decode link url to a human-readable format`
      @normalizeLinkText = NORMALIZE_LINK_TEXT

      #  Expose utils & helpers for easy acces from plugins

      @options = {}
      configure(presetName)
      set(options) if options
    end


    # chainable
    # MarkdownIt.set(options)
    #
    # Set parser options (in the same format as in constructor). Probably, you
    # will never need it, but you can change options after constructor call.
    #
    # ##### Example
    #
    # ```javascript
    # var md = require('markdown-it')()
    #             .set({ html: true, breaks: true })
    #             .set({ typographer, true });
    # ```
    #
    # __Note:__ To achieve the best possible performance, don't modify a
    # `markdown-it` instance options on the fly. If you need multiple configurations
    # it's best to create multiple instances and initialize each with separate
    # config.
    #------------------------------------------------------------------------------
    def set(options)
      assign(@options, options)
      return self
    end


    # chainable, internal
    # MarkdownIt.configure(presets)
    #
    # Batch load of all options and compenent settings. This is internal method,
    # and you probably will not need it. But if you with - see available presets
    # and data structure [here](https://github.com/markdown-it/markdown-it/tree/master/lib/presets)
    #
    # We strongly recommend to use presets instead of direct config loads. That
    # will give better compatibility with next versions.
    #------------------------------------------------------------------------------
    def configure(presets)
      raise(ArgumentError, 'Wrong `markdown-it` preset, can\'t be empty') unless presets

      unless presets.is_a? Hash
        presetName  = presets.to_sym
        presets     = CONFIG[presetName]
        raise(ArgumentError, "Wrong `markdown-it` preset #{presetName}, check name") unless presets
      end
      self.set(presets[:options]) if presets[:options]

      if presets[:components]
        presets[:components].each_key do |name|
          if presets[:components][name][:rules]
            self.send(name).ruler.enableOnly(presets[:components][name][:rules])
          end
          if presets[:components][name][:rules2]
            self.send(name).ruler2.enableOnly(presets[:components][name][:rules2])
          end
        end
      end
      return self
    end


    # chainable
    # MarkdownIt.enable(list, ignoreInvalid)
    # - list (String|Array): rule name or list of rule names to enable
    # - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    #
    # Enable list or rules. It will automatically find appropriate components,
    # containing rules with given names. If rule not found, and `ignoreInvalid`
    # not set - throws exception.
    #
    # ##### Example
    #
    # ```javascript
    # var md = require('markdown-it')()
    #             .enable(['sub', 'sup'])
    #             .disable('smartquotes');
    # ```
    #------------------------------------------------------------------------------
    def enable(list, ignoreInvalid = false)
      result = []

      list = [ list ] if !list.is_a? Array

      result << @core.ruler.enable(list, true)
      result << @block.ruler.enable(list, true)
      result << @inline.ruler.enable(list, true)
      result << @inline.ruler2.enable(list, true)
      result.flatten!


      missed = list.select {|name| !result.include?(name) }
      if !(missed.empty? || ignoreInvalid)
        raise StandardError, "MarkdownIt. Failed to enable unknown rule(s): #{missed}"
      end

      return self
    end


    # chainable
    # MarkdownIt.disable(list, ignoreInvalid)
    # - list (String|Array): rule name or list of rule names to disable.
    # - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    #
    # The same as [[MarkdownIt.enable]], but turn specified rules off.
    #------------------------------------------------------------------------------
    def disable(list, ignoreInvalid = false)
      result = []

      list = [ list ] if !list.is_a? Array

      result << @core.ruler.disable(list, true)
      result << @block.ruler.disable(list, true)
      result << @inline.ruler.disable(list, true)
      result << @inline.ruler2.disable(list, true)
      result.flatten!

      missed = list.select {|name| !result.include?(name) }
      if !(missed.empty? || ignoreInvalid)
        raise StandardError, "MarkdownIt. Failed to disable unknown rule(s): #{missed}"
      end

      return self
    end


    # chainable
    # MarkdownIt.use(plugin, params)
    #
    # Initialize and Load specified plugin with given params into current parser
    # instance. It's just a sugar to call `plugin.init_plugin(md, params)`
    #
    # ##### Example
    #
    # ```ruby
    # md = MarkdownIt::Parser.new
    # md.use(MDPlugin::Iterator, 'foo_replace', 'text',
    #        lambda {|tokens, idx|
    #          tokens[idx].content = tokens[idx].content.gsub(/foo/, 'bar')
    # })
    # ```
    #------------------------------------------------------------------------------
    def use(plugin, *args)
      plugin.init_plugin(self, *args)
      return self
    end


    # internal
    # MarkdownIt.parse(src, env) -> Array
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Parse input string and returns list of block tokens (special token type
    # "inline" will contain list of inline tokens). You should not call this
    # method directly, until you write custom renderer (for example, to produce
    # AST).
    #
    # `env` is used to pass data between "distributed" rules and return additional
    # metadata like reference info, needed for the renderer. It also can be used to
    # inject data in specific cases. Usually, you will be ok to pass `{}`,
    # and then pass updated object to renderer.
    #------------------------------------------------------------------------------
    def parse(src, env)
      state = RulesCore::StateCore.new(src, self, env)
      @core.process(state)
      return state.tokens
    end

    # MarkdownIt.render(src [, env]) -> String
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Render markdown string into html. It does all magic for you :).
    #
    # `env` can be used to inject additional metadata (`{}` by default).
    # But you will not need it with high probability. See also comment
    # in [[MarkdownIt.parse]].
    #------------------------------------------------------------------------------
    def render(src, env = {})
      # self.parse(src, { references: {} }).each {|token| pp token.to_json}

      return @renderer.render(parse(src, env), @options, env)
    end

    #------------------------------------------------------------------------------
    def to_html(src, env = {})
      render(src, env)
    end

    # internal
    # MarkdownIt.parseInline(src, env) -> Array
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # The same as [[MarkdownIt.parse]] but skip all block rules. It returns the
    # block tokens list with the single `inline` element, containing parsed inline
    # tokens in `children` property. Also updates `env` object.
    #------------------------------------------------------------------------------
    def parseInline(src, env)
      state             = RulesCore::StateCore.new(src, self, env)
      state.inlineMode  = true
      @core.process(state)
      return state.tokens
    end


    # MarkdownIt.renderInline(src [, env]) -> String
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Similar to [[MarkdownIt.render]] but for single paragraph content. Result
    # will NOT be wrapped into `<p>` tags.
    #------------------------------------------------------------------------------
    def renderInline(src, env = {})
      return @renderer.render(parseInline(src, env), @options, env)
    end

  end
end