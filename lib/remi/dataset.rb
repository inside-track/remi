module Remi

  require 'msgpack'
  require 'zlib'

  class Dataset

    def initialize
      @variables = {}
      @row = {} # I do want row to be an array, but use a has for the moment
         # or maybe not, maybe I just want the data output to file to be array, internally it can be a hash
    end


    def open(full_path)

      raw_file = File.open(full_path,"w")
      @file = Zlib::GzipWriter.new(raw_file)

    end

    def close

      @file.close

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

      @file.puts @row.to_msgpack

  #    puts "#{@row.inspect}"
    end

  end

end


=begin
def serialize_msgpack(in_filename,out_filename,columns,debug=false)

  file = File.open(out_filename,"w")
  gz = Zlib::GzipWriter.new(file)


  sum = 0
#  CSV.open(in_filename, "r", { :headers => true } ) do |rows|
  CSV.open(in_filename, "r") do |rows|


    rows.each do |row|
      puts "row: #{row.inspect}" if debug
      puts "row is class #{row.class}" if debug
      puts row.to_json if debug
      gz.puts row.to_msgpack
      sum = sum + row[columns[:physical_cases]].to_f
      line_number = $.
      puts "#{line_number}" if line_number % 50000 == 0
    end

  end
  puts "Physical_Cases: sum = #{sum}"

  gz.close

end



def deserialize_msgpack(in_filename,columns)

  sum = 0
  File.open(in_filename) do |file|

    gz = Zlib::GzipReader.new(file)

    gz.each do |row_msgpack|
      row = MessagePack.unpack(row_msgpack.chomp)
      sum += row[columns[:physical_cases]].to_f
    end

    gz.close

  end
  puts "Physical_Cases: sum = #{sum}"


end
=end
