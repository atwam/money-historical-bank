Gem::Specification.new do |s|
  s.name = "money-historical-bank"
  s.version = "0.0.2"
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage = "http://github.com/coutud/#{s.name}"
  s.authors = "Damien Couture"
  s.email = "wam@atwam.com"
  s.description = "A gem that provides rates for the money gem. Able to handle history (rates varying in time), and auto download rates from open-exchange-rates. Highly inspired by money-open-exchange-rates gem."
  s.summary = "A gem that offers exchange rates varying in time."
  s.extra_rdoc_files = %w(README.markdown)
  s.files = Dir["LICENSE", "README.markdown", "Gemfile", "lib/**/*.rb", 'test/**/*']
  s.test_files = Dir.glob("test/*_test.rb")
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.add_dependency "yajl-ruby", ">=0.8.3"
  s.add_dependency "money", ">=3.7.1"
  s.add_development_dependency "minitest", ">=2.0"
  s.add_development_dependency "rr", ">=1.0.4"
end
