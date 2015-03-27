fixture_dir = File.join(File.dirname(__FILE__), '../../../spec/motion-markdown-it/fixtures')

#------------------------------------------------------------------------------
describe "CommonMark Specs" do 
  parser      = MarkdownIt::Parser.new(:commonmark)
  specfile    = File.join(fixture_dir, 'commonmark', 'good.txt')
  tests       = get_tests(specfile)

  if ENV['example']
    define_test(tests[ENV['example'].to_i - 1], parser, true)
  else
    tests.each do |t|
      define_test(t, parser)
    end
  end

  it "another" do
    expect(true).to eq true
  end
end
