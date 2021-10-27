# frozen_string_literal: true

require 'English'
require File.expand_path('lib/rspec/retry/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Yusuke Mito', 'Michael Glass']
  gem.email         = ['mike@noredink.com']
  gem.description   = 'retry intermittently failing rspec examples'
  gem.summary       = 'retry intermittently failing rspec examples'
  gem.homepage      = 'http://github.com/NoRedInk/rspec-retry'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'rspec-retry'
  gem.require_paths = ['lib']
  gem.version       = RSpec::Retry::VERSION
  gem.add_runtime_dependency(%(rspec-core), '>3.3')
  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'byebug', '~>9.0.6' # 9.1 deprecates ruby 2.1
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rspec'
end
