require File.expand_path('../lib/motion-markdown-it/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'motion-markdown-it'
  gem.version       = MotionMarkdownIt::VERSION
  gem.authors       = ["Brett Walker", "Vitaly Puzrin", "Alex Kocharin"]
  gem.email         = 'github@digitalmoksha.com'
  gem.summary       = "Ruby version markdown-it"
  gem.description   = "Ruby/RubyMotion version of markdown-it"
  gem.homepage      = 'https://github.com/digitalmoksha/motion-markdown-it'
  gem.licenses      = ['MIT']

  gem.files         = Dir.glob('lib/**/*.rb')
  gem.files        << 'README.md'
  gem.test_files    = Dir["spec/**/*.rb"]

  gem.require_paths = ["lib"]

  gem.add_dependency 'mdurl-rb', '~> 1.0'
  gem.add_dependency 'uc.micro-rb', '~> 1.0'
  gem.add_dependency 'linkify-it-rb', '~> 2.0'

  gem.add_development_dependency 'motion-expect', '~> 2.0' # required for Travis build to work
end