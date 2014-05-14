$LOAD_PATH << '../lib'

require 'rubygems'
require 'bundler/setup'

require 'remi'
require 'benchmark'

include Remi
Log.level Logger::DEBUG
