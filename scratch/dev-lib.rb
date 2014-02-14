# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"

# Re-load my dev library
load "#{File.dirname(__FILE__)}/../lib/remi/datalib.rb"


work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}

puts work

work.mydata
work.toast



class Myclass

  def initialize
    @myprop = "This is my property"
  end

  attr_accessor :myprop

  def recurse
    self
  end

end



=begin

# How I want libraries to be defined and used

datalib work directory "/Users/gnilrets/Desktop/work"
datalib <name> <type> <path/options>

work.mydata -- returns a dataset object named mydata in the work library
  # must search through a directory (defined above) and look for dataset with a matching name


#-- ways I might accomplish something similar with Ruby
work = Datalib.new :directory "/Users/gnilrets/Desktop/work"

work = Datalib.new :directory => {:dir_name => "/Users/gnilrets/Desktop/work"}


=end
