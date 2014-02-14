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


    def return_dataset(dataset_name)
      puts "This is supposed to return a dataset named #{dataset_name}"
    end

    alias method_missing return_dataset


    def to_s

      if @type == :directory
        "Datalib: :#{@type} => #{@options[:dirname]}"
      else
        "Datalib: Undefined"
      end

    end






    private

    def validate_directory_options

      unless @options.has_key?(:dirname)
        raise "ERROR: :dirname not defined for directory library"
      end

      unless @options[:dirname].is_a?(String)
        raise "ERROR: dirname is not a string"
      end

      unless File.directory?(@options[:dirname])
        raise "ERROR: #{@options[:dirname]} does not exist"
      end

    end

  end
end
