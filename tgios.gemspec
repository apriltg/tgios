# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tgios/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'tgios'
  gem.version       = Tgios::VERSION
  gem.licenses      = ['BSD']

  gem.authors  = ['April Tsang', 'William Yeung']
  gem.email = ['april@tofugear.com', 'william@tofugear.com']

  gem.description = <<-DESC
A package of ruby-motion libraries written by our team.
  DESC

  gem.summary = 'A package of ruby-motion libraries written by our team.'
  gem.homepage = 'https://github.com/apriltg/tgios'

  gem.files       = `git ls-files`.split($\)
  gem.require_paths = ['lib']
  gem.test_files  = gem.files.grep(%r{^spec/})
  gem.add_dependency 'sugarcube', '1.1.0'
  #gem.add_dependency 'sugarcube-classic'
  gem.add_dependency 'awesome_print_motion'
  gem.add_dependency 'motion-layout'
  gem.add_dependency 'plastic_cup', '>=0.1.1'
end
