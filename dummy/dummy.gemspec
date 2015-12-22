$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dummy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dummy"
  s.version     = Dummy::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Dummy."
  s.description = "TODO: Description of Dummy."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.5"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "pry"
end
