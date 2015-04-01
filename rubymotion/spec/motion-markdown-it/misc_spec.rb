describe 'API' do

  #------------------------------------------------------------------------------
  it 'constructor' do
    expect {
      MarkdownIt::Parser.new('bad preset')
    }.to raise_error

    # options should override preset
    md = MarkdownIt::Parser.new(:commonmark, { html: false })
    expect(md).not_to eq nil
    expect(md.render('one')).to eq "<p>one</p>\n"
    expect(md.render('<!-- -->')).to eq "<p>&lt;!-- --&gt;</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'configure coverage' do
    md = MarkdownIt::Parser.new

    # conditions coverage
    md.configure({})
    expect(md.render('123')).to eq "<p>123</p>\n"

    expect {
      md.configure
    }.to raise_error
  end

  #------------------------------------------------------------------------------
  it 'plugin' do
    @success = false
    plugin = lambda {|plugin, opts| @success = true if (opts == 'bar') }

    md = MarkdownIt::Parser.new

    md.use(plugin, 'foo')
    expect(@success).to eq false
    md.use(plugin, 'bar')
    expect(@success).to eq true
  end

  #------------------------------------------------------------------------------
  it 'highlight' do
    md = MarkdownIt::Parser.new({
      highlight: lambda do |str, obj|
        return '==' + str + '=='
      end
    })

    expect(md.render("```\nhl\n```")).to eq  "<pre><code>==hl\n==</code></pre>\n"
  end

  #------------------------------------------------------------------------------
  it 'highlight escape by default' do
    md = MarkdownIt::Parser.new({highlight: lambda {|value, obj| return nil }})
    
    # assert.strictEqual(md.render("```\n&\n```"), "<pre><code>&amp;\n</code></pre>\n");
    expect(md.render("```\n&\n```")).to eq "<pre><code>&amp;\n</code></pre>\n"
  end

  #------------------------------------------------------------------------------
  it 'force hardbreaks' do
    md = MarkdownIt::Parser.new({ breaks: false })
    expect(md.render("a\nb")).to eq "<p>a\nb</p>\n"
    
    md.set({ breaks: true })
    expect(md.render("a\nb")).to eq "<p>a<br>\nb</p>\n"
    md.set({ xhtmlOut: true })
    expect(md.render("a\nb")).to eq "<p>a<br />\nb</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'xhtmlOut enabled' do
    md = MarkdownIt::Parser.new({ xhtmlOut: true })

    expect(md.render('---')).to eq "<hr />\n"
    expect(md.render('![]()')).to eq "<p><img src=\"\" alt=\"\" /></p>\n"
    expect(md.render("a  \\\nb")).to eq "<p>a  <br />\nb</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'xhtmlOut disabled' do
    md = MarkdownIt::Parser.new

    expect(md.render('---')).to eq "<hr>\n"
    expect(md.render('![]()')).to eq "<p><img src=\"\" alt=\"\"></p>\n"
    expect(md.render("a  \\\nb")).to eq "<p>a  <br>\nb</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'bulk enable/disable rules in different chains' do
    md = MarkdownIt::Parser.new

    was = {
      core:   md.core.ruler.getRules('').length,
      block:  md.block.ruler.getRules('').length,
      inline: md.inline.ruler.getRules('').length
    }

    # Disable 2 rule in each chain & compare result
    md.disable([ 'block', 'inline', 'code', 'fence', 'emphasis', 'entity' ])

    now = {
      core:   md.core.ruler.getRules('').length + 2,
      block:  md.block.ruler.getRules('').length + 2,
      inline: md.inline.ruler.getRules('').length + 2
    }

    expect(was).to eq now

    # Enable the same rules back
    md.enable([ 'block', 'inline', 'code', 'fence', 'emphasis', 'entity' ])

    back = {
      core:   md.core.ruler.getRules('').length,
      block:  md.block.ruler.getRules('').length,
      inline: md.inline.ruler.getRules('').length
    }

    expect(was).to eq back
  end

  #------------------------------------------------------------------------------
  it 'bulk enable/disable with errors control' do
    md = MarkdownIt::Parser.new
    expect {
      md.enable([ 'link', 'code', 'invalid' ])
    }.to raise_error

    expect {
      md.disable([ 'link', 'code', 'invalid' ])
    }.to raise_error

    expect {
      md.enable([ 'link', 'code' ])
    }.to_not raise_error

    expect {
      md.disable([ 'link', 'code' ])
    }.to_not raise_error
  end

  #------------------------------------------------------------------------------
  it 'bulk enable/disable should understand strings' do
    md = MarkdownIt::Parser.new

    md.disable('emphasis')
    expect(md.renderInline('_foo_')).to eq '_foo_'

    md.enable('emphasis')
    expect(md.renderInline('_foo_')).to eq '<em>foo</em>'
  end

end


#------------------------------------------------------------------------------
describe 'Misc' do

  #------------------------------------------------------------------------------
  it 'Should replace NULL characters' do
    md = MarkdownIt::Parser.new

    expect(md.render("foo\u0000bar")).to eq "<p>foo\\uFFFDbar</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'Should correctly parse strings without tailing \\n' do
    md = MarkdownIt::Parser.new

    expect(md.render('123')).to eq "<p>123</p>\n"
    expect(md.render("123\n")).to eq "<p>123</p>\n"
  end

  #------------------------------------------------------------------------------
  it 'Should quickly exit on empty string' do
    md = MarkdownIt::Parser.new

    expect(md.render('')).to eq ''
  end

  #------------------------------------------------------------------------------
  it 'Should parse inlines only' do
    md = MarkdownIt::Parser.new

    expect(md.renderInline('a *b* c')).to eq 'a <em>b</em> c'
  end

  #------------------------------------------------------------------------------
  it 'Renderer should have pluggable inline and block rules' do
    md = MarkdownIt::Parser.new

    md.renderer.rules['em_open']         = lambda {|tokens, idx, options, env, renderer| return '<it>' }
    md.renderer.rules['em_close']        = lambda {|tokens, idx, options, env, renderer| return '</it>' }
    md.renderer.rules['paragraph_open']  = lambda {|tokens, idx, options, env, renderer| return '<par>' }
    md.renderer.rules['paragraph_close'] = lambda {|tokens, idx, options, env, renderer| return '</par>' }

    expect(md.render('*b*')).to eq '<par><it>b</it></par>'
  end

  #------------------------------------------------------------------------------
  it 'Zero preset should disable everything' do
    md = MarkdownIt::Parser.new(:zero)

    expect(md.render('___foo___')).to eq "<p>___foo___</p>\n"
    expect(md.renderInline('___foo___')).to eq '___foo___'

    md.enable('emphasis')

    expect(md.render('___foo___')).to eq "<p><strong><em>foo</em></strong></p>\n"
    expect(md.renderInline('___foo___')).to eq '<strong><em>foo</em></strong>'
  end

  #------------------------------------------------------------------------------
  it 'Should correctly check block termination rules when those are disabled (#13)' do
    md = MarkdownIt::Parser.new(:zero)

    expect(md.render("foo\nbar")).to eq "<p>foo\nbar</p>\n"
  end

  # TODO ------------------------------------------------------------------------------
  # it 'Should render link target attr' do
  #   md = MarkdownIt::Parser.new.
  #               use(require('markdown-it-for-inline'), 'target', 'link_open', function (tokens, idx) {
  #                 tokens[idx].attrs.push([ 'target', '_blank' ]);
  #               });
  #
  #   assert.strictEqual(md.render('[foo](bar)'), '<p><a href="bar" target="_blank">foo</a></p>\n');
  # end

end


#------------------------------------------------------------------------------
describe 'Url normalization' do

  #------------------------------------------------------------------------------
  it 'Should be overridable' do
    md = MarkdownIt::Parser.new({ linkify: true })

    md.normalizeLink = lambda do |url|
      expect(/example\.com/ =~ url).to_not eq nil
      return 'LINK'
    end
    
    md.normalizeLinkText = lambda do |url|
      expect(/example\.com/ =~ url).to_not eq nil
      return 'TEXT'
    end

    expect(md.render('foo@example.com')).to eq "<p><a href=\"LINK\">TEXT</a></p>\n"
    expect(md.render('http://example.com')).to eq "<p><a href=\"LINK\">TEXT</a></p>\n"
    expect(md.render('<foo@example.com>')).to eq "<p><a href=\"LINK\">TEXT</a></p>\n"
    expect(md.render('<http://example.com>')).to eq "<p><a href=\"LINK\">TEXT</a></p>\n"
    expect(md.render('[test](http://example.com)')).to eq "<p><a href=\"LINK\">test</a></p>\n"
    expect(md.render('![test](http://example.com)')).to eq "<p><img src=\"LINK\" alt=\"test\"></p>\n"
  end

end


#------------------------------------------------------------------------------
describe 'Links validation' do

  #------------------------------------------------------------------------------
  it 'Override validator, disable everything' do
    md = MarkdownIt::Parser.new({ linkify: true })

    md.validateLink = lambda { |url| return false }

    expect(md.render('foo@example.com')).to eq "<p>foo@example.com</p>\n"
    expect(md.render('http://example.com')).to eq "<p>http://example.com</p>\n"
    expect(md.render('<foo@example.com>')).to eq "<p>&lt;foo@example.com&gt;</p>\n"
    expect(md.render('<http://example.com>')).to eq "<p>&lt;http://example.com&gt;</p>\n"
    expect(md.render('[test](http://example.com)')).to eq "<p>[test](http://example.com)</p>\n"
    expect(md.render('![test](http://example.com)')).to eq "<p>![test](http://example.com)</p>\n"
  end

end


#------------------------------------------------------------------------------
describe 'maxNesting' do

  #------------------------------------------------------------------------------
  it 'Inline parser should not nest above limit' do
    md = MarkdownIt::Parser.new({ maxNesting: 2 })
    expect(md.render('*foo *bar *baz* bar* foo*')).to eq "<p><em>foo <em>bar *baz* bar</em> foo</em></p>\n"
  end

  #------------------------------------------------------------------------------
  it 'Block parser should not nest above limit' do
    md = MarkdownIt::Parser.new({ maxNesting: 2 })
    expect(md.render(">foo\n>>bar\n>>>baz")).to eq "<blockquote>\n<p>foo</p>\n<blockquote></blockquote>\n</blockquote>\n"
  end

end
