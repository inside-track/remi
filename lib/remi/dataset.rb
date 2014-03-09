module Remi
  include Log

  ## Methods that act on datasets

  def datastep(*dataset)

    raise "datastep called, no block given" if not block_given?

    logger.debug "DATASTEP> #{dataset}"

    dataset.each do |ds|
      ds.open_for_write
    end

    yield *dataset
  ensure
    dataset.each do |ds|
      ds.close_and_write_header
    end
  end


  def read(dataset)
    logger.debug "DATASET.READ> **#{dataset.name}**"

    dataset.open_for_read

    begin
      while dataset.readrow
        yield dataset
      end
    rescue EOFError
    end

  ensure
    dataset.close
  end


  class Dataset
    include Log

    attr_reader :name, :_N_
    attr_accessor :vars

    def initialize(datalib,name,lib_options)
      @datalib = datalib
      @name = name

      @header_file_full_path = ""
      @header_file = nil
      @header_stream = nil

      @data_file_full_path = ""
      @data_file = nil
      @data_stream = nil

      if lib_options.has_key?(:directory)
        @header_file_full_path = File.join(lib_options[:directory][:dirname],"#{@name}.hgz")
        @data_file_full_path = File.join(lib_options[:directory][:dirname],"#{@name}.rgz")
      end

      @_N_ = 0

      @vars = Variables.new

    end


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
      logger.info "DATASET.OPEN> **<#{@datalib}.#{@name}** for write"
      logger.debug "  Data file #{@data_file_full_path}"
      logger.debug "  Header file #{@header_file_full_path}"

      # Header kept as stream in case we want to have multi-row headers
      raw_header_file = File.open(@header_file_full_path,"w")
      @header_file = Zlib::GzipWriter.new(raw_header_file)
      @header_stream = MessagePack::Packer.new(@header_file)

      raw_data_file = File.open(@data_file_full_path,"w")
      @data_file = Zlib::GzipWriter.new(raw_data_file)
      @data_stream = MessagePack::Packer.new(@data_file)
    end


    def open_for_read
      logger.info "DATASET.OPEN_FOR_READ> **<#{@datalib}.#{@name}** for read"
      logger.debug "  Data file #{@data_file_full_path}"
      logger.debug "  Header file #{@header_file_full_path}"

      raw_header_file = File.open(@header_file_full_path,"r")
      @header_file = Zlib::GzipReader.new(raw_header_file)
      @header_stream = MessagePack::Unpacker.new(@header_file)

      raw_data_file = File.open(@data_file_full_path,"r")
      @data_file = Zlib::GzipReader.new(raw_data_file)
      @data_stream = MessagePack::Unpacker.new(@data_file)

      import_header
    end


    def import_header
      @header_stream.each do |header_row|
        header = symbolize_keys(header_row)
        logger.debug "  Reading metadata #{header}"

        header.each do |key,value|
          @vars.var key, value[:meta]
        end
      end
    end


    def close_and_write_header
      @header_stream.write(@vars.to_header).flush
    ensure
      close
    end


    def close
      logger.info "DATASET.CLOSE> **#{@datalib}.#{@name}**"

      @header_file.close
      @data_file.close
    end


    def output
      # Consider flushing every N rows and write_array_header
      @data_stream.write(@vars.values).flush
      @_N_ += 1
    end


    def row_to_log
      logger.debug "#{vars.values}"
    end


    def readrow
      @vars.values = @data_stream.read
      @_N_ += 1
    end


    def set_values(ds)
      ds.vars.each_with_values do |name,obj,value|
        @vars[name] = value if @vars.has_key?(name)
      end
    end


    def to_s
      msg = <<-EOF.unindent
        ----    DATASET    ----
        This is dataset #{@name} <#{self.object_id}> in library #{@datalib}

        --  VARIABLES  --
      EOF
      @vars.each_with_values do |name,var_obj,value|
        msg << "#{name} = #{value} | #{var_obj.meta}\n"
      end
      msg
    end
  end
end


