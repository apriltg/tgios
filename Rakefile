# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
  require 'motion-stump'
  require 'sugarcube'
  require 'plastic_cup'
  require 'plastic_cup/stylesheet'
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'tgios'
  app.identifier = 'com.tofugear.tgios'
  app.specs_dir = "spec/"
end
