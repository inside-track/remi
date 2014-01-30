#!/usr/bin/ruby

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


=end


def datastep(dataset)

end

# I think I need a variable class too
# then I could define an assignment operator for that

class Dataset

  def initialize
    @variables = {}
    @row = {} # I do want row to be an array, but use a has for the moment
       # or maybe not, maybe I just want the data output to file to be array, internally it can be a hash
  end

  def add_variable(varname,varmeta)

    tmpvarlist = @variables.merge({ varname => varmeta })
    
    if not tmpvarlist[varname].has_key?(:type)
      raise ":type not defined for variable #{varname}"
    end

    @variables = tmpvarlist
    @row[varname] = nil
    
  end

  def []=(varname,value)
    if @row.has_key?(varname)
      @row[varname] = value
    else
      raise "Variable '#{varname}' not defined"
    end
  end

  def [](varname)
    @row[varname]
  end

  def output

    printf "|"
    @row.each do |key,value|
      printf "#{key}=#{value}|"
    end
    printf "\n"

#    puts "#{@row.inspect}"
  end

end

mydata = Dataset.new()

mydata.add_variable(:n, { :type => "num" })
mydata.add_variable(:retailer_id, { :type => "string", :length => 40 })

for num in 1..3
  mydata[:n] = num
  mydata[:retailer_id] = "R#{mydata[:n]}"
  mydata.output
end

# want to do someting like this
# the datastep is what opens and closes the files
#  It also advances through the datastep
#  It also does an automatic "output" unless disabled
=begin

datastep mydata do |d1|

  d1.add_variable({:msg => {:type => :string, :length => 20}})

  for num in 1..3
    d1.var(:msg) = "Hello #{num}"
    d1.output
  end

end


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

=begin
data mydata;
  set input_set;

  x = x**2;
run;
=end
