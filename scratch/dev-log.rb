# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"


# Re-load my dev library
load "#{File.dirname(__FILE__)}/../lib/remi/log.rb"

Log.level(Logger::DEBUG)
x = Testlogger.new
