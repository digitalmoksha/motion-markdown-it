describe "Token" do

  it 'attr' do
    t = MarkdownIt::Token.new('test_token', 'tok', 1)

    expect(t.attrs).to eq nil
    expect(t.attrIndex('foo')).to eq -1

    t.attrPush([ 'foo', 'bar' ])
    t.attrPush([ 'baz', 'bad' ])

    expect(t.attrIndex('foo')).to eq 0
    expect(t.attrIndex('baz')).to eq 1
    expect(t.attrIndex('none')).to eq -1
  end

end
