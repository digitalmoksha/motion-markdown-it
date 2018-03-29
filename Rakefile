require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

desc 'Run benchmarks for motion-markdown-it, kramdown, and commonmarker'
task :benchmark do
  require 'benchmark'
  require 'motion-markdown-it'
  require 'kramdown'
  require 'commonmarker'

  runs          = 500
  files         = ['mdsyntax.text', 'mdbasics.text']
  benchmark_dir = File.join(File.dirname(__FILE__), 'benchmark')

  puts
  puts "Running tests on #{Time.now.strftime("%Y-%m-%d")} under #{RUBY_DESCRIPTION}"

  files.each do |file|
    data = File.read(File.join(benchmark_dir, file))
    puts
    puts "==> Test using file #{file} and #{runs} runs"

    results = Benchmark.bmbm(25) do |b|
    # results = Benchmark.bm(25) do |b|
      b.report("motion-markdown-it #{MotionMarkdownIt::VERSION}") do
        parser = MarkdownIt::Parser.new({ html: true, linkify: true, typographer: true })
        runs.times { parser.render(data) }
      end
      b.report("kramdown #{Kramdown::VERSION}") { runs.times { Kramdown::Document.new(data).to_html } }
      b.report("commonmarker #{CommonMarker::VERSION}") { runs.times { CommonMarker.render_html(data, :DEFAULT) } }
    end

    puts
    puts "Real time as a factor of motion-markdown-it"

    md_real = results.first.real
    results.each do |result|
      puts result.label.ljust(28) << (result.real / md_real).round(4).to_s
    end
  end
end