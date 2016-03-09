File.expand_path(File.join(File.dirname(__FILE__),'../lib')).tap {|pwd| $LOAD_PATH.unshift(pwd) unless $LOAD_PATH.include?(pwd)}

require 'rubygems'
require 'bundler/setup'

require 'remi'

include Remi
