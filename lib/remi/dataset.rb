module Remi
  class Dataset
    include Log

    attr_reader :name, :_N_, :EOF
    attr_accessor :vars, :row, :prev_row, :next_row

    def initialize(datalib,name,lib_options)
      @datalib = datalib
      @name = name

      @is_open = false
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

      @_N_ = nil # not initialized until open is set
      @EOF = false

      @vars = {}
      @row = []
      @prev_row = []
      @next_row = []

      @by_groups = []
      @by_first = {}
      @by_last = {}

    end

    def [](var_name)
      @row[@vars[var_name].position] if variable_defined?(var_name)
    end

    def prev(var_name)
      @prev_row[@vars[var_name].position] if variable_defined?(var_name)
    end

    def next(var_name)
      @next_row[@vars[var_name].position] if variable_defined?(var_name)
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

    def length
      @row.length
    end

    
    def first(*var_name)
      if var_name.length == 0
        @by_first[@by_groups[-1]]
      else
        @by_first[var_name[0]]
      end
    end

    def last(*var_name)
      if var_name.length == 0
        @by_last[@by_groups[-1]]
      else
        @by_last[var_name[0]]
      end
    end

    def initialize_by_groups(by_groups=[])
      @by_groups = by_groups
      @by_groups.each do |var_name|
        @by_first[var_name] = nil if variable_defined?(var_name)
        @by_last[var_name] = nil if variable_defined?(var_name)
      end
    end

    def has_by_groups?
      @by_groups.length > 0
    end

    def update_by_groups
      parent_first = false
      parent_last = false
      @by_groups.each do |var_name|
        @by_first[var_name] = ((self[var_name] != self.prev(var_name)) or parent_first)
        @by_last[var_name] = ((self[var_name] != self.next(var_name)) or parent_last)

        parent_first = @by_first[var_name]
        parent_last = @by_last[var_name]
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

      @is_open =true
      @_N_ = 1
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

      @is_open = true
      import_header
      @_N_ = 0
    end

    def is_open?
      @is_open
    end

    def import_header
      @header_stream.each do |header_row|
        symbolize_keys(header_row).each do |key,value|
          @vars[key] = Variables::Variable.new(value[:metadata],value[:position])
        end
        logger.debug "  Reading metadata #{@vars}"
      end
      
      @row = [nil] * @vars.length
      @prev_row = @row.dup
      @next_row = @row.dup
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
      @is_open = false
    end


    def read_row_from(dataset, keep: nil, drop: [])
      # This is really just a shortcut method for reading an input
      # dataset that uses the same variable names.  If the names are
      # different, the mapping should be done explicitly.
      # If any variables are in dataset, but not in self, they are ignored.
      # You would really only want to use keep/drop if you wanted to make
      # sure that the same variable name was not imported from dataset
      @vars.each do |var_name,var_obj|
        next if drop.include? var_name
        next unless keep.nil? || (keep.include? var_name)
        self[var_name] = dataset[var_name] if dataset.vars.has_key?(var_name)
      end
    end


    def write_row
      # Consider flushing every N rows and write_array_header
      @prev_row = @row.dup
      @data_stream.write(@row).flush
      @_N_ += 1
    end


    def row_to_log
      logger.debug "#{@row}"
    end


    def read_row
      begin
        prev_row = @row.dup # don't want to update @prev_row if read fails
        if @_N_ > 0
          @row = @next_row
          @EOF = @next_EOF
          return false if @EOF
        else
          begin
            @row = @data_stream.read
          rescue EOFError
            @EOF = true
            return false
          end
        end
        @prev_row = prev_row
        @_N_ += 1

        begin
          @next_EOF = false
          @next_row = @data_stream.read
        rescue EOFError
          @next_row = [nil] * @row.length
          @next_EOF = true
        end
        update_by_groups if has_by_groups?

        true
      rescue EOFError
        @EOF = true
        false
      end
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
      msg
    end
  end
end
