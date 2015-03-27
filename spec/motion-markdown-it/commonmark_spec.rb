#------------------------------------------------------------------------------
describe "CommonMark Specs" do 

  parser    = MarkdownIt::Parser.new(:commonmark)
  specfile  = File.join(File.dirname(__FILE__), 'fixtures', 'commonmark', 'good.txt')
  tests     = get_tests(specfile)
  
  if ENV['example']
    define_test(tests[ENV['example'].to_i - 1], parser, true)
  else
    tests.each do |t|
      define_test(t, parser)
    end
  end
  
end