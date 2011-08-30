# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'lib', 'cycle_chef_handler')

# copy README.rdoc to README.txt
FileUtils.cp File.join(File.dirname(__FILE__), 'README.rdoc'), File.join(File.dirname(__FILE__), 'README.txt') 

# we don't use rubyforge
Hoe.plugins.delete :rubyforge

Hoe.spec 'cycle_chef_handler' do
  developer('Chris Chalfant', 'chris.chalfant@cyclecomputing.com')
  extra_deps << ['chef']
  extra_deps << ['bunny']
  extra_deps << ['classad']
end

