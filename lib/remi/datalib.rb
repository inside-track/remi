module Remi

  class Datalib

    def initialize(args)

      @type = :undefined
      @options = {}

      unless args.is_a?(Hash)
        raise "Must pass options hash"
      end

      if args.has_key?(:directory)

        @type = :directory
        @options = args[:directory]

        validate_directory_options()

      else
        raise "Unknown library type #{type}"
      end
      
    end

    def validate_directory_options

      unless @options.has_key?(:dir_name)
        raise "ERROR: dir_name not defined for directory library"
      end

      unless @options[:dir_name].is_a?(String)
        raise "ERROR: dir_name is not a string"
      end

    end

    def dataset_exists?
    end

    def return_dataset
    end

    def to_s

      if @type == :directory
        "Datalib: #{@type}, #{@options[:dir_name]}"
      else
        "Datalib: Undefined"
      end

    end

  end

end
