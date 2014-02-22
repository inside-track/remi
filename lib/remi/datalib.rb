module Remi

  class Datalib
    
    # initialization
    #  work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}


    def initialize(args)

      @type = :undefined
      @options = {}

      unless args.is_a?(Hash)
        raise "Must pass options hash"
      end

      if args.has_key?(:directory)

        @type = :directory
        @options = args

        validate_directory_options()

      else
        raise "Unknown library type #{type}"
      end
      
    end


    def return_dataset(dataset_name)

      Dataset.new(self,dataset_name,@options)

    end

    alias method_missing return_dataset


    def to_s

      if @type == :directory
        "Datalib: :#{@type} => #{@options[:directory][:dirname]}"
      else
        "Datalib: Undefined"
      end

    end






    private

    def validate_directory_options

      unless @options[:directory].has_key?(:dirname)
        raise "ERROR: :dirname not defined for directory library"
      end

      unless @options[:directory][:dirname].is_a?(String)
        raise "ERROR: dirname is not a string"
      end

      unless File.directory?(@options[:directory][:dirname])
        raise "ERROR: #{@options[:directory][:dirname]} does not exist"
      end

    end

  end
end
