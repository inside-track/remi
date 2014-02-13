# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"

# Re-load my dev library
load "#{File.dirname(__FILE__)}/../lib/remi/library.rb"





=begin

# How I want libraries to be defined and used

datalib work directory "/Users/gnilrets/Desktop/work"
datalib <name> <type> <path/options>

work.mydata -- returns a dataset object named mydata in the work library
  # must search through a directory (defined above) and look for dataset with a matching name

=end
