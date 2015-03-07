module Remi
  # Public: Provides a common interface for developers to create new data libs.
  # This is a generic DataLib class that delegates calls to more specific
  # data lib classes.
  #
  # Examples
  #
  #   # This will create a DataLibs::CanonicalDataLib object with dir_name
  #   DataLib.new(dir_name: RemiConfig.work_dirname)
  class DataLib < SimpleDelegator

    # Public: Gets the type of data lib
    attr_reader :data_lib_type

    # Public: DataLib initializer.
    #
    # type - Symbol used to set the type of data lib to create (default: :directory).
    # args - Passes any additional arguments onto the initializer of the specific data lib.
    def initialize(type = :directory, **args)
      @data_lib = nil

      # Used to pass non-null key-word arguments to specific libs
      arg_parse = lambda { |args, keys| args.select { |k,v| v && Array(keys).include?(k) } }

      case type
      when :canonical, :directory
        @data_lib = DataLibs::CanonicalDataLib.new(arg_parse.call(args, [:dir_name]))
      when :basic
        @data_lib = DataLibs::BasicDataLib.new
      when :delimited_text
        @data_lib = DataLibs::DelimitedTextDataLib.new(arg_parse.call(args, [:dir_name, :file_pattern, :header_as_variables, :csv_opt]))
      end

      @data_lib_type = @data_lib.class.name
      super(@data_lib)
    end
  end
end
