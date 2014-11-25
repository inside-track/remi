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

      case type
      when :canonical, :directory
        @data_lib = DataLibs::CanonicalDataLib.new(args[:dir_name])
      end

      @data_lib_type = @data_lib.class.name
      super(@data_lib)
    end
  end
end
