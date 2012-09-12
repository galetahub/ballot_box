# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ballot_box/version"

Gem::Specification.new do |s|
  s.name = "ballot_box"
  s.version = BallotBox::VERSION.dup
  s.platform = Gem::Platform::RUBY 
  s.summary = "The BallotBox gem enables visitors to vote for and against voteable objects"
  s.description = "The BallotBox gem enables visitors to vote for and against voteable objects"
  s.authors = ["Igor Galeta"]
  s.email = "galeta.igor@gmail.com"
  s.rubyforge_project = "ballot_box"
  s.homepage = "https://github.com/galetahub/ballot_box"
  
  s.files = Dir["{app,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.test_files = Dir["{spec}/**/*"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.require_paths = ["lib"]
  
  s.add_dependency("browser", "~> 0.1.4")
  s.add_dependency("activemodel", ">= 0")
end
