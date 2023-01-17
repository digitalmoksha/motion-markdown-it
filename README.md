# motion-markdown-it

[![Gem Version](https://badge.fury.io/rb/motion-markdown-it.svg)](http://badge.fury.io/rb/motion-markdown-it)
[![Build Status](https://github.com/digitalmoksha/motion-markdown-it/actions/workflows/ci.yml/badge.svg)](https://github.com/digitalmoksha/motion-markdown-it/actions/workflows/ci.yml)

Ruby/RubyMotion version of Markdown-it (CommonMark compliant and extendable)

This gem is a port of the [markdown-it Javascript package](https://github.com/markdown-it/markdown-it) by Vitaly Puzrin and Alex Kocharin. 

_Currently synced with markdown-it 12.0.4_

---

__[Javascript Live demo](https://markdown-it.github.io)__

Follows the __[CommonMark spec](http://spec.commonmark.org/)__ + adds syntax extensions & sugar (URL autolinking, typographer).
- Configurable syntax. You can add new rules and even replace existing ones.
- [Safe](https://github.com/markdown-it/markdown-it/tree/master/docs/security.md) by default.
- Community-written plugins
  * [Ruby/RubyMotion](https://github.com/digitalmoksha/motion-markdown-it-plugins)
  * [original javascript plugins](https://www.npmjs.org/browse/keyword/markdown-it-plugin) and [other packages](https://www.npmjs.org/browse/keyword/markdown-it) on npm.

## Benefit

The benefit of this project, for me at least, is to have a standardized CommonMark compliant, fast, and extendable, Markdown parser which can be used from Javascript, Ruby, and/or RubyMotion, as the development situation warrants.

## Performance

Performance is slower than, say, `kramdown`, but for most uses, is pretty fast.  Here are some non-scientific benchmarks.  Note that `kramdown` and `redcarpet` are not CommonMark compliant.

```
Running tests on 2018-04-04 under ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin16]

==> Test using file mdsyntax.text and 500 runs
Rehearsal -------------------------------------------------------------
motion-markdown-it 8.4.1   17.940000   0.710000  18.650000 ( 18.721629)
kramdown 1.16.2            14.720000   0.180000  14.900000 ( 15.015840)
commonmarker 0.17.9         0.220000   0.000000   0.220000 (  0.222098)
redcarpet 3.4.0             0.140000   0.010000   0.150000 (  0.145821)
--------------------------------------------------- total: 33.920000sec

                                user     system      total        real
motion-markdown-it 8.4.1   18.290000   0.720000  19.010000 ( 19.113943)
kramdown 1.16.2            13.320000   0.110000  13.430000 ( 13.459096)
commonmarker 0.17.9         0.190000   0.000000   0.190000 (  0.187104)
redcarpet 3.4.0             0.120000   0.000000   0.120000 (  0.123931)

Real time as a factor of motion-markdown-it
motion-markdown-it 8.4.1    1.0
kramdown 1.16.2             0.7042
commonmarker 0.17.9         0.0098
redcarpet 3.4.0             0.0065
````

## Table of content

- [Install](#install)
- [Usage examples](#usage-examples)
  - [Simple](#simple)
  - [Init with presets and options](#init-with-presets-and-options)
- [Plugins](#plugins)
- [Upgrading](#upgrading)
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
parser.render('# markdown-it in **Ruby**')
```

Single line rendering, without paragraph wrap:

```ruby
result = MarkdownIt::Parser.new.renderInline('__markdown-it__ in Ruby')
```

### Init with presets and options

(*) presets define combinations of active rules and options. Can be
`:commonmark`, `:zero` or `:default` (if skipped).

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
  # For the full list of replacements, see https://github.com/markdown-it/markdown-it/blob/master/lib/rules_core/replacements.js
  typographer:  false,

  # Double + single quotes replacement pairs, when typographer enabled,
  # and smartquotes on. Could be either a String or an Array.
  #
  # For example, you can use '«»„“' for Russian, '„“‚‘' for German,
  # and ['«\xA0', '\xA0»', '‹\xA0', '\xA0›'] for French (including nbsp).
  quotes: '“”‘’',

  # Highlighter function. Should return escaped HTML,
  # or nil if the source string is not changed and should be escaped externally.
  highlight: lambda {|str, lang| return nil}
})
```

## Plugins

Plugins can be used to extend the syntax and functionality.  A [sample set of plugins](https://github.com/digitalmoksha/motion-markdown-it-plugins) has been created based on those already created for the javascript version.  Included are:

* [Abbreviations](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/abbr)
* [Checkbox/Tasklists](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/checkbox_replace)
* [Containers](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/container)
* [Definition Lists](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/deflist)
* [Insert](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/ins)
* [Mark](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/mark)
* [Subscript](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/sub)
* [Superscript](https://github.com/digitalmoksha/motion-markdown-it-plugins/tree/master/lib/motion-markdown-it-plugins/sup)

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
var hljs = require('highlight.js'); // https://highlightjs.org/

// Actual default values
var md = require('markdown-it')({
  highlight: function (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return hljs.highlight(lang, str).value;
      } catch (__) {}
    }

    return ''; // use external default escaping
  }
});
```

Or with full wrapper override (if you need assign class to `<pre>`):

```js
var hljs = require('highlight.js'); // https://highlightjs.org/

// Actual default values
var md = require('markdown-it')({
  highlight: function (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return '<pre class="hljs"><code>' +
               hljs.highlight(lang, str, true).value +
               '</code></pre>';
      } catch (__) {}
    }

    return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>';
  }
});
```

### Linkify

`linkify: true` uses [linkify-it](https://github.com/markdown-it/linkify-it). To
configure linkify-it, access the linkify instance through `md.linkify`:

```js
md.linkify.set({ fuzzyEmail: false });  // disables converting email to link
```


## API

__[API documentation](https://markdown-it.github.io/markdown-it/)__

If you are going to write plugins - take a look at
[Development info](https://github.com/markdown-it/markdown-it/tree/master/docs).


## Syntax extensions

Embedded (enabled by default):

- [Tables](https://help.github.com/articles/organizing-information-with-tables/) (GFM)
- [Strikethrough](https://help.github.com/articles/basic-writing-and-formatting-syntax/#styling-text) (GFM)

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
load all its rules are enabled automatically.

```js
// Activate/deactivate rules, with curring
var md = require('markdown-it')()
            .disable([ 'link', 'image' ])
            .enable([ 'link' ])
            .enable('image');

// Enable everything
md = require('markdown-it')({
  html: true,
  linkify: true,
  typographer: true,
});
```

You can find all rules in sources:
[parser_core.js](lib/parser_core.js), [parser_block](lib/parser_block.js),
[parser_inline](lib/parser_inline.js).


## Benchmark

Here is the result of readme parse at MB Pro Retina 2013 (2.4 GHz):

```bash
make benchmark-deps
benchmark/benchmark.js readme

Selected samples: (1 of 28)
 > README

Sample: README.md (7774 bytes)
 > commonmark-reference x 1,222 ops/sec ±0.96% (97 runs sampled)
 > current x 743 ops/sec ±0.84% (97 runs sampled)
 > current-commonmark x 1,568 ops/sec ±0.84% (98 runs sampled)
 > marked x 1,587 ops/sec ±4.31% (93 runs sampled)
```

__Note.__ CommonMark version runs with [simplified link normalizers](https://github.com/markdown-it/markdown-it/blob/master/benchmark/implementations/current-commonmark/index.js)
for more "honest" compare. Difference is ~ 1.5x.

As you can see, `markdown-it` doesn't pay with speed for it's flexibility.
Slowdown of "full" version caused by additional features not available in
other implementations.


-->

## Upgrading

Upgrading to `8.4.1.2` could cause some small breakage if you are using any custom plugins.  The [motion-markdown-it-plugins](https://github.com/digitalmoksha/motion-markdown-it-plugins) plugins have already been upgraded.

#### charCodeAt

Make sure you have

```ruby
include MarkdownIt::Common::Utils
```

at the top of your plugin file.  Then change any references to `charCodeAt`.  For example,

```ruby
state.src.charCodeAt(pos)
```

would become

```ruby
charCodeAt(state.src, pos)
```

#### slice_to_end

`slice_to_end` has been removed.  Change references like this

```ruby
state.src.slice_to_end(pos)
```

to

```ruby
state.src[pos..-1]
```

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
