# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"

require 'test/unit'
require 'benchmark'

# Load all test files
$LOAD_PATH << File.dirname(__FILE__)

#require 'remi/Datalib/test_datalib'
#require 'remi/Dataset/test_write_and_read'

Log.level Logger::DEBUG


