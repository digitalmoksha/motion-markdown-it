describe 'Ruler' do

  #------------------------------------------------------------------------------
  it 'should replace rule (.at)' do
    ruler = MarkdownIt::Ruler.new
    res = 0

    ruler.push('test', lambda { res = 1 })
    ruler.at('test', lambda { res = 2 })

    rules = ruler.getRules('')

    expect(rules.length).to eq 1
    rules[0].call
    expect(res).to eq 2
  end


  #------------------------------------------------------------------------------
  it 'should inject before/after rule' do
    ruler = MarkdownIt::Ruler.new
    res = 0

    ruler.push('test', lambda { res = 1 })
    ruler.before('test', 'before_test', lambda { res = -10; })
    ruler.after('test', 'after_test', lambda { res = 10; })

    rules = ruler.getRules('');

    expect(rules.length).to eq 3
    rules[0].call
    expect(res).to eq -10
    rules[1].call
    expect(res).to eq 1
    rules[2].call
    expect(res).to eq 10
  end


  #------------------------------------------------------------------------------
  it 'should enable/disable rule' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})
    ruler.push('test2', lambda {})

    rules = ruler.getRules('')
    expect(rules.length).to eq 2

    ruler.disable('test')
    rules = ruler.getRules('')
    expect(rules.length).to eq 1
    ruler.disable('test2')
    rules = ruler.getRules('')
    expect(rules.length).to eq 0

    ruler.enable('test')
    rules = ruler.getRules('')
    expect(rules.length).to eq 1
    ruler.enable('test2')
    rules = ruler.getRules('')
    expect(rules.length).to eq 2
  end


  #------------------------------------------------------------------------------
  it 'should enable/disable multiple rule' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})
    ruler.push('test2', lambda {})

    ruler.disable([ 'test', 'test2' ])
    rules = ruler.getRules('')
    expect(rules.length).to eq 0
    ruler.enable([ 'test', 'test2' ])
    rules = ruler.getRules('')
    expect(rules.length).to eq 2
  end


  #------------------------------------------------------------------------------
  it 'should enable rules by whitelist' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})
    ruler.push('test2', lambda {})

    ruler.enableOnly('test')
    rules = ruler.getRules('')
    expect(rules.length).to eq 1
  end


  #------------------------------------------------------------------------------
  it 'should support multiple chains' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})
    ruler.push('test2', lambda {}, { alt: [ 'alt1' ] })
    ruler.push('test2', lambda {}, { alt: [ 'alt1', 'alt2' ] })

    rules = ruler.getRules('')
    expect(rules.length).to eq 3
    rules = ruler.getRules('alt1')
    expect(rules.length).to eq 2
    rules = ruler.getRules('alt2');
    expect(rules.length).to eq 1
  end


  #------------------------------------------------------------------------------
  it 'should fail on invalid rule name' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})

    expect {
      ruler.at('invalid name', lambda {})
    }.to raise_error(StandardError)
    expect {
      ruler.before('invalid name', lambda {})
    }.to raise_error(StandardError)
    expect {
      ruler.after('invalid name', lambda {})
    }.to raise_error(StandardError)
    expect {
      ruler.enable('invalid name')
    }.to raise_error(StandardError)
    expect {
      ruler.disable('invalid name')
    }.to raise_error(StandardError)
  end


  #------------------------------------------------------------------------------
  it 'should not fail on invalid rule name in silent mode' do
    ruler = MarkdownIt::Ruler.new

    ruler.push('test', lambda {})

    expect {
      ruler.enable('invalid name', true)
    }.not_to raise_error
    expect {
      ruler.enableOnly('invalid name', true)
    }.not_to raise_error
    expect {
      ruler.disable('invalid name', true)
    }.not_to raise_error
  end

end
