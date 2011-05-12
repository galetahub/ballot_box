# encoding: utf-8
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.join(File.dirname(__FILE__), 'lib', 'ballot_box', 'version')

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the ballot_box plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the ballot_box plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BallotBox'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "ballot_box"
    s.version = BallotBox::VERSION.dup
    s.summary = "The BallotBox gem enables visitors to vote for and against voteable objects"
    s.description = "The BallotBox gem enables visitors to vote for and against voteable objects"
    s.email = "galeta.igor@gmail.com"
    s.homepage = "https://github.com/galetahub/ballot_box"
    s.authors = ["Igor Galeta", "Pavlo Galeta"]
    s.files =  FileList["[A-Z]*", "{app,lib}/**/*"] - ["Gemfile"]
    #s.extra_rdoc_files = FileList["[A-Z]*"]
  end
  
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
