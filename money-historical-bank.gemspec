Gem::Specification.new do |s|
  s.name = "money-historical-bank"
  s.version = "0.0.4"
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage = "http://github.com/atwam/#{s.name}"
  s.authors = ["atwam", "Jon Allured"]
  s.email = ["wam@atwam.com", "jon.allured@gmail.com"]
  s.description = "A gem that provides rates for the money gem. Able to handle history (rates varying in time), and auto download rates from open-exchange-rates. Highly inspired by money-open-exchange-rates gem."
  s.summary = "A gem that offers exchange rates varying in time."
  s.extra_rdoc_files = %w(README.md)
  s.files = Dir["LICENSE", "README.md", "Gemfile", "lib/**/*.rb", 'test/**/*']
  s.test_files = Dir.glob("test/*_test.rb")
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.license = "MIT"
  s.add_dependency "yajl-ruby", "~>0.8", ">=0.8.3"
  s.add_dependency "money", "~>3.7", ">=3.7.1"
  s.add_development_dependency "minitest", "~>2.0", ">=2.0"
  s.add_development_dependency "rr", "~>1.0", ">=1.0.4"
end
