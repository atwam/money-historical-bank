# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'money-historical-bank'
  spec.version = '0.0.4'
  spec.authors = ['atwam', 'Jon Allured']
  spec.email = ['wam@atwam.com', 'jon.allured@gmail.com']

  spec.summary = 'A gem that offers exchange rates varying in time.'
  spec.description = 'A gem that provides rates for the money gem. Able to handle history (rates varying in time), and auto download rates from open-exchange-rates. Highly inspired by money-open-exchange-rates gem.'
  spec.homepage = 'http://github.com/atwam/money-historical-bank'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.files = Dir['LICENSE', 'README.md', 'Gemfile', 'lib/**/*.rb', 'test/**/*']
  spec.extra_rdoc_files = %w[README.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'money', '~>6', '>=6.13.1'
  spec.add_dependency 'yajl-ruby', '~>1.3', '>=1.3.1'

  spec.add_development_dependency 'minitest', '~>5', '>=5.0'
  spec.add_development_dependency 'rr', '~>1.0', '>=1.0.4'
  spec.add_development_dependency 'rubocop'
end
