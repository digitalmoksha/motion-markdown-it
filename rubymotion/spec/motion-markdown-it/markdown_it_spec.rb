fixture_dir = File.join(File.dirname(__FILE__), '../../../spec/motion-markdown-it/fixtures')

#------------------------------------------------------------------------------
describe "markdown-it" do 

  parser    = MarkdownIt::Parser.new({ html: true, langPrefix: '', typographer: true, linkify: true })
  datafiles = File.join(fixture_dir, 'markdown-it', '**/*')

  Dir[datafiles].each do |data_file|
    tests = get_tests(data_file)
    if ENV['example']
      define_test(tests[ENV['example'].to_i - 1], parser, true)
    else
      tests.each do |t|
        define_test(t, parser)
      end
    end
  end  
end
