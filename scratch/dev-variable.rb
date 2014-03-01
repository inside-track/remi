# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"

# Re-load my dev library
load "#{File.dirname(__FILE__)}/../lib/remi/datalib.rb"
load "#{File.dirname(__FILE__)}/../lib/remi/dataset.rb"
load "#{File.dirname(__FILE__)}/../lib/remi/variables.rb"


def rand_string(n=10)
  (0..n).map { ('A'..'Z').to_a[rand(26)]}.join
end

def test_datastep

  work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}

  datastep work.mydata do |d1|

    d1.define_variables do

      var :rownum, :type => :number
      var :retailer_key, :type => :string
      var :physical_cases, :type => :number
    
    end


    for i in 1..3

      d1[:rownum] = i
      d1[:retailer_key] = rand_string()
      d1[:physical_cases] = rand(100)

      d1.output()

    end


  end

end




def test_variable

  position = -1
  myvar1 = Variable.new position+=1, {}
  myvar2 = Variable.new position+=1, :type => :string

  puts "Initial set"
  puts myvar1
  puts myvar2

  puts "Modify metadata"
  myvar2.add_meta :type => :number, :cdc_type => 2
  puts myvar2

  puts "Swap variable position"
  myvar1.swap_position(myvar2)

  puts myvar1
  puts myvar2

end

test_variable
