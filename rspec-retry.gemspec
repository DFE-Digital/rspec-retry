# frozen_string_literal: true

require 'English'
require File.expand_path('lib/rspec/retry/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Yusuke Mito', 'Michael Glass', 'James Glenn', 'Steve Laing']
  gem.email         = ['james.glenn@digital.education.gov.uk']
  gem.description   = 'Retry intermittently failing rspec examples – This is an extension to the original gem and will log the flakey tests'
  gem.summary       = 'Retry intermittently failing rspec examples – This is an extension to the original gem and will log the flakey tests'
  gem.homepage      = 'https://github.com/DFE-Digital/rspec-retry'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.name          = 'rspec-retry'
  gem.require_paths = ['lib']
  gem.version       = RSpec::Retry::VERSION
  gem.add_runtime_dependency(%(rspec-core), '>3.3')
  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'byebug', '~>9.0.6' # 9.1 deprecates ruby 2.1
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rspec'
  gem.metadata['rubygems_mfa_required'] = 'true'
end
