=begin
* Think about a class structure for rows and fields
  * Read a csv, and create a set of fields (with user-extensible metadata)
  * Populate those fields from the csv file and define some sort of
    serialization method that could write out blocks of data to a dataset
	(that would hold the metadata in it)
  * Dataset class needs block methods to loop over rows
    * With group-by style first.dot last.dot processing and retain functionality
	  (don't do lag, but do have a retain function - perhaps retain is the default
	  for block variables)
    * Hash lookups
	* Build and process sub-datasets ?  that might be cool!


* A dataset is a thing that references a file, a list of variables, and has a row iterator
* A datastep takes datasets as output arguments and iterates over input datasets

=end

require 'benchmark'


# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"


# Re-load my dev library
load "#{File.dirname(__FILE__)}/../lib/remi/datalib.rb"
load "#{File.dirname(__FILE__)}/../lib/remi/dataset.rb"
load "#{File.dirname(__FILE__)}/../lib/remi/variables.rb"


def rand_string(n=10)
  (0..n).map { ('A'..'Z').to_a[rand(26)]}.join
end
def test_dataset_variables
  work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}
  work.mydata_multivar.define_variables do

    var :retailer_key, :type => :string
    var :physical_cases, :type => :number
    
  end

end

#test_dataset_variables




def test_datastep

  work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}

  datastep work.mydata do |d1|

    myvar = []
    d1.define_variables do

      var :rownum, :type => :number
      var :retailer_key, :type => :string
      var :physical_cases, :type => :number

      for i in 1..10
        myvar << "myvar_#{i}".to_sym
        var myvar[i-1], :type => :string
      end
    
    end

    for i in 1..10000
      d1[:rownum] = i
      d1[:retailer_key] = "AKDFKJDdKDJFKJOIFWIEFWEOFIHOQIHFOQIHFOIEHFOIEHFOIEFHOIEHFOsihfoihEOIFhsofishISEHFOSIHFOISHFOZIHFIOZEHFOEHFIOZEHFEOZIHIFHZOFINIEOVNIEN"
      d1[:physical_cases] = 385.18356

      for i in 1..10
        d1[myvar[i-1]] = "0123456789" * 10
      end

      d1.output()

    end

  end

end

time = Benchmark.realtime do
  test_datastep
end
puts "Time: #{time}"





=begin
def test_build_dataset
  mydata = Dataset.new()

  mydata.open("/Users/gnilrets/Desktop/mydata.gz")

  mydata.add_variable(:n, { :type => "num" })
  mydata.add_variable(:retailer_id, { :type => "string", :length => 40 })

  for num in 1..3
    mydata[:n] = num
    mydata[:retailer_id] = "R#{mydata[:n]}"
    mydata.output
  end

  mydata.close

end
=end



# want to do someting like this
# the datastep is what opens and closes the files
#  It also advances through the datastep
#  It also does an automatic "output" unless disabled

=begin

## Ok, but how do I really WANT it to work (ignore ruby, figure that out later).


# Data generation

datalib = "~/Desktop"
dataset datalib.mydata do

  variables do

    distributor_id string
    retailer_id string
    product_id string
    physical_cases number

  end

  do i = 1 to 20

    distributor_id = rand()
    retailer_id = rand()
    product_id = rand()
    physical_cases = rand()

    mydata.output

  end

end


# Data read
datalib = "~/Desktop"
dataset datalib.mydata do

  variables do

    distributor_id string
    retailer_id string
    product_id string
    physical_cases number

  end

  read mycsv do |mycsv| # variables must be explicitly declared above and set
  
    distributor_id = mycsv[0]
    retialer_id = mycsv[1]
    product_id = mycsv[2]
    physical_cases = myscsv[3]

    mydata.output()

  end

end


# Data modify

dataset datalib.mydata_modified do

  varaibles import mydata (exclude source_file) # and use a keep too

  variables do

    volume number

  end

  read datalib.mydata do # variables in mydat_modified are implicitly set by mydata (or do I need to explicitly set them?????)

    volume = physical_cases * conv_factor[product_id] # conv_factor is some locally genrated hash

    mydata_modified.output()

  end

end


# Multiple output

dataset datalib.mydata_split_1 datalib.mydata_split_2 do |d1,d2|

  d1.variables import datalib.mydata (keep retailer_key physical_cases)
  d2.variables import datalib.mydata (keep distributor_key physical_cases)

  read datalib.mydata do

    d1.output()
    d2.output()

  end 

end


# Data sort

#    Rule: Do not sort or modify datasets in place.  Provide a delete function.

sorted datalib.mydata_modified_sorted do
  sort datalib.mydata_modified by
    retailer_key
    distributor_key
  end
end


# First/last processing

dataset datalib.mydata_by_distributor do

  read datalib.mydata_modified_sorted do

    by retailer_key

    variables do
      sum_physical_cases number
      drop physical_cases
    end


    if first.retailer_key
      sum_physical_cases = 0
    end

    sum_physical_cases = sum_physical_cases + physical_cases

    if last.retailer_key
      output()
    end

  end

end




# Data merge

merged datalib.mydata_merged datalib.unknown do |d1,u1|

  merge datalib.rad datalib.products do |rad,products|

    by rad.product_key = products.product_key

    if in rad and in products
      d1.output()
    end

    if in rad and not in products
      u1.output()
    end

  end

end


# I think I want to be able to define a dataset at runtime





# But also at other times (mayb eby defining a null dataset that gets created later)




=end

=begin

class Dataset

  def initialize(columns)
    @columns = columns
    @row = []
    @position = 0
    @file = ""
  end

  def add_column
  end

  def output
  end

  columns = {}

  def show_columns


    if block_given?
      @columns.each do |key,val|
        yield val
      end
    end

    @columns.values if not block_given?

  end



end


mydata = Dataset.new({
                       1 => "distributor_id",
                       2 => "retailer_id",
                       3 => "physical_cases"
                     });

puts mydata.inspect


mydata.show_columns do |f|
  puts f
end

x = mydata.show_columns
puts "x = #{x.inspect}"

#=begin
data mydata;
  set input_set;

  x = x**2;
run;
=end
