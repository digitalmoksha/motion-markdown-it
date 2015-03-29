require 'kramdown'

runs          = 50
files         = ['mdsyntax.text', 'mdbasics.text']
benchmark_dir = File.join(File.dirname(__FILE__), '../../benchmark')

puts
puts "Running tests on #{Time.now.strftime("%Y-%m-%d")} under #{RUBY_DESCRIPTION}"

files.each do |file|
  data = File.read(File.join(benchmark_dir, file))
  puts
  puts "==> Test using file #{file} and #{runs} runs"

  # results = Benchmark.bmbm do |b|
  results = Benchmark.bm do |b|
    b.report("motion-markdown-it 0.1.0") do
      parser = MarkdownIt::Parser.new({ html: true, linkify: true, typographer: true })
      runs.times { parser.render(data) }
    end
    b.report("kramdown #{Kramdown::VERSION}") { runs.times { Kramdown::Document.new(data).to_html } }
    # b.report("markdown-it 4.0.1 JS") { runs.times { NSApplication.sharedApplication.delegate.markdown_it(data) } }
    # b.report(" hoedown 3.0.1") do
    #   runs.times do
    #     document = HoedownDocument.new
    #     document.initWithHtmlRendererWithFlags(FLAGS)
    #     html = document.renderMarkdownString(data)
    #   end
    # end
  end

  # puts
  # puts "Real time of X divided by real time of kramdown"
  # kd = results.shift.real
  # %w[hoedown].each do |name|
  #   puts name.ljust(19) << (results.shift.real/kd).round(4).to_s
  # end
end

describe "Benchmark Test" do
  it "benchmarks with mdsyntax.text and mdbasics.text" do
    expect(true).to eq true
  end
end
