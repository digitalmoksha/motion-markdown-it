# motion-markdown-it

[![Gem Version](https://badge.fury.io/rb/motion-markdown-it.svg)](http://badge.fury.io/rb/motion-markdown-it)

Ruby/RubyMotion version of Markdown-it (CommonMark compliant and extendable)

This gem is a port of the [markdown-it Javascript package](https://github.com/markdown-it/markdown-it) by Vitaly Puzrin and Alex Kocharin.

__[Javascript Live demo](https://markdown-it.github.io)__

- Supports the CommonMark spec + syntax extensions + sugar (URL autolinking, typographer)
- Configurable syntax. You can add new rules and even replace existing ones.
- High speed
- Community-written plugins

## Beta

The gem is still a work in progress.  There are several areas to get working better, including plugins and performance.  It will track as closely as possible to fixes and enhancements in the main _markdown-it_ implementation. Currently synced with markdown-it 4.0.3

## Benefit

The benefit of this project, for me at least, is to have a standardized CommonMark compliant, fast, and extendable, Markdown parser which can be used from Javascript, Ruby, and/or RubyMotion, as the development situation warrants.

## Table of content

- [Install](#install)
- [Usage examples](#usage-examples)
- [References / Thanks](#references--thanks)
- [License](#license)

<!--
- [API](#api)
- [Syntax extensions](#syntax-extensions)
- [Benchmark](#benchmark)
-->

## Install

### Ruby

Add it to your project's `Gemfile`

	gem 'motion-markdown-it'

and run `bundle install`

### RubyMotion

Add it to your project's `Gemfile`

	gem 'motion-markdown-it'

Edit your `Rakefile` and add

	require 'motion-markdown-it'

and run `bundle install`


## Usage examples

### Simple

```ruby
parser = MarkdownIt::Parser.new(:commonmark, { html: false })
parser.render('# markdown-it rulezz!')
```

Single line rendering, without paragraph wrap:

```ruby
result = MarkdownIt::Parser.new.renderInline('__markdown-it__ rulezz!')
```

### Init with presets and options

(*) preset define combination of active rules and options. Can be
`:commonmark`, `:zero` or `:default` (if skipped). You can refer to the 
[markdown-it Javascript API docs](https://markdown-it.github.io/markdown-it/#MarkdownIt.new) for more details.

```ruby
#--- commonmark mode
parser = MarkdownIt::Parser.new(:commonmark)

#--- default mode
parser = MarkdownIt::Parser.new

#--- enable everything
parser = MarkdownIt::Parser.new({ html: true, linkify: true, typographer: true })

#--- full options list (defaults)
parser = MarkdownIt::Parser.new({
  html:         false,        # Enable HTML tags in source
  xhtmlOut:     false,        # Use '/' to close single tags (<br />).
                              # This is only for full CommonMark compatibility.
  breaks:       false,        # Convert '\n' in paragraphs into <br>
  langPrefix:   'language-',  # CSS language prefix for fenced blocks. Can be
                              # useful for external highlighters.
  linkify:      false,        # Autoconvert URL-like text to links

  # Enable some language-neutral replacement + quotes beautification
  typographer:  false,

  # Double + single quotes replacement pairs, when typographer enabled,
  # and smartquotes on. Set doubles to '«»' for Russian, '„“' for German.
  quotes: '“”‘’',

  # Highlighter function. Should return escaped HTML,
  # or '' if the source string is not changed and should be escaped externaly.
  highlight: lambda {|str, lang| return ''}
})
```

<!--
### Plugins load

```js
var md = require('markdown-it')()
            .use(plugin1)
            .use(plugin2, opts, ...)
            .use(plugin3);
```


### Syntax highlighting

Apply syntax highlighting to fenced code blocks with the `highlight` option:

```js
var hljs = require('highlight.js') // https://highlightjs.org/

// Actual default values
var md = require('markdown-it')({
  highlight: function (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return hljs.highlight(lang, str).value;
      } catch (__) {}
    }

    try {
      return hljs.highlightAuto(str).value;
    } catch (__) {}

    return ''; // use external default escaping
  }
});
```


## API

__[API documentation](https://markdown-it.github.io/markdown-it/)__

If you are going to write plugins - take a look at
[Development info](https://github.com/markdown-it/markdown-it/tree/master/docs).


## Syntax extensions

Embedded (enabled by default):

- [Tables](https://help.github.com/articles/github-flavored-markdown/#tables) (GFM)
- [Strikethrough](https://help.github.com/articles/github-flavored-markdown/#strikethrough) (GFM)

Via plugins:

- [subscript](https://github.com/markdown-it/markdown-it-sub)
- [superscript](https://github.com/markdown-it/markdown-it-sup)
- [footnote](https://github.com/markdown-it/markdown-it-footnote)
- [definition list](https://github.com/markdown-it/markdown-it-deflist)
- [abbreviation](https://github.com/markdown-it/markdown-it-abbr)
- [emoji](https://github.com/markdown-it/markdown-it-emoji)
- [custom container](https://github.com/markdown-it/markdown-it-container)
- [insert](https://github.com/markdown-it/markdown-it-ins)
- [mark](https://github.com/markdown-it/markdown-it-mark)
- ... and [others](https://www.npmjs.org/browse/keyword/markdown-it-plugin)


### Manage rules

By default all rules are enabled, but can be restricted by options. On plugin
load all it's rules are enabled automatically.

```js
// Activate/deactivate rules, with curring
var md = require('markdown-it')()
            .disable([ 'link', 'image' ])
            .enable([ 'link' ])
            .enable('image');

// Enable everything
md = require('markdown-it')('full', {
  html: true,
  linkify: true,
  typographer: true,
});
```


## Benchmark

Here is result of readme parse at MB Pro Retina 2013 (2.4 GHz):

```bash
$ benchmark/benchmark.js readme
Selected samples: (1 of 28)
 > README

Sample: README.md (7774 bytes)
 > commonmark-reference x 1,222 ops/sec ±0.96% (97 runs sampled)
 > current x 743 ops/sec ±0.84% (97 runs sampled)
 > current-commonmark x 1,568 ops/sec ±0.84% (98 runs sampled)
 > marked-0.3.2 x 1,587 ops/sec ±4.31% (93 runs sampled)
```

__Note.__ CommonMark version runs with [simplified link normalizers](https://github.com/markdown-it/markdown-it/blob/master/benchmark/implementations/current-commonmark/index.js)
for more "honest" compare. Difference is ~ 1.5x.

As you can see, `markdown-it` doesn't pay with speed for it's flexibility.
Slowdown of "full" version caused by additional features, not available in
other implementations.

-->

## References / Thanks

Thanks to the authors of the original implementation in Javascript, [markdown-it](https://github.com/markdown-it/markdown-it):

- Alex Kocharin [github/rlidwka](https://github.com/rlidwka)
- Vitaly Puzrin [github/puzrin](https://github.com/puzrin)

and to [John MacFarlane](https://github.com/jgm) for his work on the
CommonMark spec and reference implementations.

**Related Links:**

- https://github.com/jgm/CommonMark - reference CommonMark implementations in C & JS,
  also contains latest spec & online demo.
- http://talk.commonmark.org - CommonMark forum, good place to collaborate
  developers' efforts.

## License

[MIT](https://github.com/digitalmoksha/motion-markdown-it/blob/master/LICENSE)
