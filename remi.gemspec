# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "remi/version"

Gem::Specification.new do |s|
  s.name        = "remi"
  s.version     = Remi::VERSION
  s.authors     = ["Sterling Paramore"]
  s.email       = ["gnilrets@gmail.com"]
  s.homepage    = "https://github.com/gnilrets"
  s.license     = "Apache-2.0"
  s.summary     = "Remi (Ruby Extract Modify and Integrate)"
  s.description = "Data manipulation and ETL in Ruby"

  s.rubyforge_project = "Remi"
  s.add_runtime_dependency "google_visualr", ["~> 2.2"]
  s.add_runtime_dependency "launchy", ["~> 2.4"]
  s.add_runtime_dependency "msgpack", ["~> 0.5"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
