module Remi
  class Dataset
    include Log

    attr_reader :name, :_N_
    attr_accessor :vars, :row

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

      @vars = {}
      @row = []
    end

    def [](var_name)
      @row[@vars[var_name].position] if variable_defined?(var_name)
    end

    def []= var_name,value
      @row[@vars[var_name].position] = value if variable_defined?(var_name)
    end

    def variable_defined?(var_name)
      if @vars.has_key?(var_name)
        true
      else
        msg = "Variable #{var_name} not defined for dataset #{@name}"
        logger.error msg
        raise NameError, msg
        false
      end
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
        symbolize_keys(header_row).each do |key,value|
          @vars[key] = Variables::Variable.new(value[:metadata],value[:position])
        end
        logger.debug "  Reading metadata #{@vars}"
      end
    end


    def close_and_write_header
      header = {}
      @vars.each do |var_name,var_obj|
        header.merge!(var_name => var_obj.to_hash)
      end
      @header_stream.write(header).flush
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
      @data_stream.write(@row).flush
      @_N_ += 1
    end


    def row_to_log
      logger.debug "#{@row}"
    end


    def readrow
      @row = @data_stream.read
      @_N_ += 1
    end


    def to_s
      msg = <<-EOF.unindent
        ----    DATASET    ----
        This is dataset #{@name} <#{self.object_id}> in library #{@datalib}

        --  VARIABLES  --
      EOF
      
      @vars.each do |var_name,var_obj|
        msg << "#{var_name} = #{var_obj}\n"
      end
      
#      @vars.each_with_values do |name,var_obj,value|
#        msg << "#{name} = #{value} | #{var_obj.meta}\n"
#      end
      msg
    end
  end
end
