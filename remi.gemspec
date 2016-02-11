# -*- encoding: utf-8 mode: ruby -*-
$:.push File.expand_path("../lib", __FILE__)
require "remi/version"

Gem::Specification.new do |s|
  s.name        = "remi"
  s.version     = Remi::VERSION
  s.authors     = ["Sterling Paramore"]
  s.email       = ["sterling.paramore@insidetrack.com"]
  s.homepage    = "https://github.com/inside-track/remi"
  s.license     = "MIT"
  s.summary     = "Remi (Ruby Extract Map Integrate)"
  s.description = "Data manipulation and ETL in Ruby"

  s.rubyforge_project = "Remi"
  s.add_runtime_dependency "daru", ["~> 0.1"]

  s.add_runtime_dependency 'bond', ['~> 0.5']
  s.add_runtime_dependency 'docile', ['~> 1.1']
  s.add_runtime_dependency 'net-sftp', ['~> 2.1']
  s.add_runtime_dependency 'pg', ['~> 0.18']
  s.add_runtime_dependency 'regex_sieve', ['~> 0.1']

  s.add_runtime_dependency "cucumber", ["~> 2.1"]
  s.add_runtime_dependency "rspec", ["~> 3.3"]
  s.add_runtime_dependency "regexp-examples", ["~> 1.1"]

  s.add_runtime_dependency "activesupport", ["~> 4.2"]

  # Move these into separate package
  s.add_runtime_dependency 'restforce', ['~> 2.1']
  s.add_runtime_dependency 'salesforce_bulk_api', ['0.0.12']

  s.add_development_dependency 'iruby', ['0.2.7']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
