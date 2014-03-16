$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

require 'msgpack'
require 'zlib'
require 'launchy'
require 'google_visualr'
require 'json'
require 'erb'
require 'fileutils'
require 'csv'

require 'remi/config'
require 'remi/core_additions'
require 'remi/helpers'
require 'remi/version'
require 'remi/log'
require 'remi/dataset'
require 'remi/datalib'
require 'remi/variables'
require 'remi/datastep'
require 'remi/dataview'
require 'remi/csv'

include Remi
