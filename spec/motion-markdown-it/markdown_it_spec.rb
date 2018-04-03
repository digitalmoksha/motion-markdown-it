#------------------------------------------------------------------------------
describe "markdown-it" do

  parser    = MarkdownIt::Parser.new({ html: true, langPrefix: '', typographer: true, linkify: true })
  datadir   = File.join(File.dirname(__FILE__), 'fixtures', 'markdown-it')
  datafiles = (ENV['datafile'] ? [ File.join(datadir, ENV['datafile']) ] : Dir[File.join(datadir, '**/*')])

  datafiles.each do |data_file|
    tests = get_tests(data_file)
    if ENV['example'] && !tests[ENV['example'].to_i - 1].nil?
      define_test(tests[ENV['example'].to_i - 1], parser, true)
    else
      tests.each do |t|
        define_test(t, parser)
      end
    end
  end
end