# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "traversal/version"

Gem::Specification.new do |s|
  s.name        = "traversal"
  s.version     = Traversal::VERSION
  s.authors     = ["Alexey Mikhaylov"]
  s.email       = ["amikhailov83@gmail.com"]
  s.homepage    = "https://github.com/take-five/traversal"
  s.summary     = %q{Simple traversal API for pure Ruby objects}
  s.date        = "2012-01-22"

  s.rubyforge_project = "traversal"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  # s.add_runtime_dependency "rest-client"
end
