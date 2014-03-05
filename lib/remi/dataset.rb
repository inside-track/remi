module Remi

  require 'msgpack'
  require 'zlib'

  # Stolen from http://devblog.avdi.org/2009/07/14/recursively-symbolize-keys/
  # Not sure I really like it.  Might want to convert to a hash method
  def symbolize_keys(hash)
    hash.inject({}){|result, (key, value)|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
      result
    }
  end


  def datastep(*dataset)

    include Log

    raise "datastep called, no block given" if not block_given?

    logger.debug "Starting datastep #{dataset}"

    dataset.each do |ds|
      ds.open_for_write
    end

    yield *dataset

    dataset.each do |ds|
      ds.close_and_write_header
    end

  end


  def read(dataset)

    include Log

    logger.debug "Reading dataset #{dataset.name}"

    dataset.open_for_read
    yield dataset
    dataset.close

  end



  class Dataset

    include Log

    def initialize(datalib,name,lib_options)

      # Initialize should check to see if dataset exists
      # If so, read variables and other dataset options
      # If not, initialize an empty dataset

      @datalib = datalib
      @name = name

      @header_file_full_path = ""
      @data_file_full_path = ""

      @header_file = nil
      @data_file = nil

      if lib_options.has_key?(:directory)

        @header_file_full_path = File.join(lib_options[:directory][:dirname],"#{@name}.hgz")
        @data_file_full_path = File.join(lib_options[:directory][:dirname],"#{@name}.rgz")

      end

      @vars = Variables.new

    end

    attr_reader :name
    attr_accessor :vars


    # Variables get evaluated in a module to separate the namespace
    def define_variables(&b)

      @vars.evaluate_block_vars(&b)

    end

    # Variable accessor
    def [](varname)
      @vars[varname]
    end

    # Variables assignment
    def []= varname,value
      @vars[varname] = value
    end



    def open_for_write

      logger.info "-Opening dataset for write #{@datalib}.#{@name}-"
      logger.info "Data file #{@data_file_full_path}"
      logger.info "Header file #{@header_file_full_path}"

      raw_header_file = File.open(@header_file_full_path,"w")
      @header_file = Zlib::GzipWriter.new(raw_header_file)

      raw_data_file = File.open(@data_file_full_path,"w")
      @data_file = Zlib::GzipWriter.new(raw_data_file)
      @data_stream = MessagePack::Packer.new(@data_file)

    end


    def open_for_read

      logger.info "-Opening dataset for read #{@datalib}.#{@name}-"
      logger.info "Data file #{@data_file_full_path}"
      logger.info "Header file #{@header_file_full_path}"

      raw_header_file = File.open(@header_file_full_path,"r")
      @header_file = Zlib::GzipReader.new(raw_header_file)

      raw_data_file = File.open(@data_file_full_path,"r")
      @data_file = Zlib::GzipReader.new(raw_data_file)
      @data_stream = MessagePack::Unpacker.new(@data_file)



      import_header

    end


    def import_header

      @header_file.each do |row|
        header = symbolize_keys(MessagePack.unpack(row.chomp))
        logger.debug "Reading metadata #{header}"

        header.each do |key,value|

          @vars.var key, value[:meta]

        end

      end

    end


    def close_and_write_header

      # Write header file containing metadata
      @header_file.puts @vars.to_msgpack

      close

    end

    def close

      logger.info "-Closing dataset #{@datalib}.#{@name}-"

      @header_file.close
      @data_file.close

    end





    def output

      puts "WRITING #{@vars.values} to file"
      puts "|#{@vars.values.to_msgpack}|"

#      @data_file.puts @vars.values.to_msgpack
#      @data_file.puts "#{@vars.values.to_msgpack}"
#      @vars.values.to_msgpack(@data_file)

#      @data_stream.write_array_header(@vars.values.length)
      @data_stream.write(@vars.values).flush

    end


    def readline

      line = @data_stream.read
      puts "UNPACKED #{line}"


=begin
      line = @data_file.readline.chomp
#      line = MessagePack.unpack(@data_file.readline.chomp)
      puts "READING #{line}"
      uline = MessagePack.unpack("#{line}")
      puts "UNPACKED #{uline}"
#      rescue EOFError
=end
    end

=begin
    def readline(mapto_ds)


      # hmmm... need to figure out how to just read one row here

      mapto_ds.vars.each_with_values do |name,obj,value|
        
        @vars[name] = value

      end


    end
=end

    def to_s

      msg = "\n" * 2
      msg << "-" * 4 + "DATASET" + "-" * 4 + "\n"
      msg << "This is dataset #{@name} <#{self.object_id}> in library #{@datalib}\n"
      msg << "\n"
      msg << "-" * 3 + "VARIABLES" + "-" * 3 + "\n"

      @vars.each_with_values do |name,var_obj,value|
        msg << "#{name} = #{value} | #{var_obj.meta}\n"
      end

      msg

    end

  end
end



=begin Not really thought out, but it did some stuff that might want to borrow
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
=end




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
