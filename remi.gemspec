# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "remi/version"

Gem::Specification.new do |s|
  s.name        = "remi"
  s.version     = "0.0.1"
  s.authors     = ["Sterling Paramore"]
  s.email       = ["gnilrets@gmail.com"]
  s.homepage    = "https://github.com/gnilrets"
  s.license     = "Apache-2.0"
  s.summary     = "Remi (Ruby Extract Modify and Integrate)"
  s.description = "Data manipulation in Ruby"

  s.rubyforge_project = "Remi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
