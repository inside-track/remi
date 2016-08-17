module Remi
  module DataFrame
    class Daru < SimpleDelegator
      include Remi::DataFrame

      def initialize(*args, **kargs, &block)
        if args[0].is_a? ::Daru::DataFrame
          super(args[0])
        else
          super(::Daru::DataFrame.new(*args, **kargs, &block))
        end
      end


      # Public: Returns the type of DataFrame
      def df_type
        :daru
      end

      # Public: Saves a Dataframe to a file.
      def hash_dump(filename)
        File.binwrite(filename, Marshal.dump(self))
      end

      # Public: Creates a DataFrame by reading the dumped version from a file.
      def self.from_hash_dump(filename)
        Marshal.load(File.binread(filename))
      end
    end
  end
end
