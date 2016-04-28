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
      def remi_df_type
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

      # Public: Allows the user to define an arbitrary aggregation function.
      #
      # by   - The name of the DataFrame vector to use to group records.
      # func - A lambda function that accepts three arguments - the
      #        first argument is the DataFrame, the second is the
      #        key to the current group, and the third is the index
      #        of the elements belonging to a group.
      #
      # Example:
      #   df = Remi::DataFrame::Daru.new( { a: ['a','a','a','b','b'], year: ['2018','2015','2019', '2014', '2013'] })
      #
      #   mymin = lambda do |vector, df, group_key, indices|
      #     values = indices.map { |idx| df.row[idx][vector] }
      #     "Group #{group_key} has a minimum value of #{values.min}"
      #   end
      #
      #   df.aggregate(by: :a, func: mymin.curry.(:year))
      #
      #
      # Returns a Daru::Vector.
      def aggregate(by:, func:)
        grouped = self.group_by(by)
        df_indices = self.index.to_a
        ::Daru::Vector.new(
          grouped.groups.reduce({}) do |h, (key, indices)|
            # Daru groups don't use the index of the dataframe when returning groups (WTF?).
            # Instead they return the position of the record in the dataframe.  Here, we
            group_df_indices = indices.map { |v| df_indices[v] }
            group_key = key.size == 1 ? key.first : key
            h[group_key] = func.(self, group_key, group_df_indices)
            h
          end
        )
      end

    end
  end
end
