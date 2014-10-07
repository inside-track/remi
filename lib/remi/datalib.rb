module Remi
  # Public: Provides a common interface for end users to create new data libs.
  # This is a generic Datalib class that delegates calls to more specific
  # data lib classes.
  #
  # Examples
  #
  #   # This will create a Datalibs::CanonicalDatalib object with dir_name
  #   Datalib.new(dir_name: RemiConfig.work_dirname)
  class Datalib < SimpleDelegator

    # Public: Gets the type of data lib
    attr_reader :datalib_type

    # Public: Datalib initializer.
    #
    # type - Symbol used to set the type of data lib to create (default: :directory).
    # args - Passes any additional arguments onto the initializer of the specific datalib.
    def initialize(type = :directory, **args)
      @datalib = nil

      case type
      when :canonical, :directory
        @datalib = Datalibs::CanonicalDatalib.new(args[:dir_name])
      end

      @datalib_type = @datalib.class.name
      super(@datalib)
    end
  end
end
