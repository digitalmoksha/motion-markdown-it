describe 'Utils' do
  extend MarkdownIt::Common::Utils

  #------------------------------------------------------------------------------
  it 'fromCodePoint' do
    expect(fromCodePoint(0x20)).to eq ' '
    expect(fromCodePoint(0x1F601)).to eq '😁'
  end

  #------------------------------------------------------------------------------
  it 'isValidEntityCode' do
    expect(isValidEntityCode(0x20)).to eq true
    expect(isValidEntityCode(0xD800)).to eq false
    expect(isValidEntityCode(0xFDD0)).to eq false
    expect(isValidEntityCode(0x1FFFF)).to eq false
    expect(isValidEntityCode(0x1FFFE)).to eq false
    expect(isValidEntityCode(0x00)).to eq false
    expect(isValidEntityCode(0x0B)).to eq false
    expect(isValidEntityCode(0x0E)).to eq false
    expect(isValidEntityCode(0x7F)).to eq false
  end

  #------------------------------------------------------------------------------
  it 'assign' do
    expect(assign({ a: 1 }, nil, { b: 2 })).to eq ({ a: 1, b: 2 })
    expect {
      assign({}, 123)
    }.to raise_error(StandardError)
  end

  #------------------------------------------------------------------------------
  it 'escapeRE' do
    expect(escapeRE(' .?*+^$[]\\(){}|-')).to eq ' \\.\\?\\*\\+\\^\\$\\[\\]\\\\\\(\\)\\{\\}\\|\\-'
  end

  #------------------------------------------------------------------------------
  it 'isWhiteSpace' do
    expect(isWhiteSpace(0x2000)).to eq true
    expect(isWhiteSpace(0x09)).to eq true

    expect(isWhiteSpace(0x30)).to eq false
  end

  #------------------------------------------------------------------------------
  it 'isMdAsciiPunct' do
    expect(isMdAsciiPunct(0x30)).to eq false

    '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'.split('').each do |ch|
      expect(isMdAsciiPunct(ch.ord)).to eq true
    end
  end

  #------------------------------------------------------------------------------
  it 'unescapeMd' do
    expect(unescapeMd('\\foo')).to eq '\\foo'
    expect(unescapeMd('foo')).to eq 'foo'

    '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'.split('').each do |ch|
      expect(unescapeMd('\\' + ch)).to eq ch
    end
  end

  #------------------------------------------------------------------------------
  it "escapeHtml" do
    str = '<hr>x & "y"'
    expect(escapeHtml(str)).to eq '&lt;hr&gt;x &amp; &quot;y&quot;'
  end

end
