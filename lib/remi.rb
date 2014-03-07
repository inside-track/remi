$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

require 'remi/helpers'
require 'remi/version'
require 'remi/log'
require 'remi/dataset'
require 'remi/datalib'
require 'remi/variables'

include Remi
