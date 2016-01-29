module Remi
  module Refinements
    module Daru
      refine ::Daru::DataFrame do

        # Public: Fixes dup issues in the Daru library (vectors not being duped).
        def dup
          dupdf = ::Daru::DataFrame.new([], index: self.index)
          self.vectors.each do |v|
            dupdf[v] = self[v]
          end

          dupdf
        end

        # Public: Fixes a bug where the dataframe on the left side of the
        # concatenation is accidentally modified.
        def concat other_df
          vectors = []
          @vectors.each do |v|
            vectors << self[v].dup.to_a.concat(other_df[v].to_a)
          end

          Daru::DataFrame.new(vectors, order: @vectors)
        end

        # Public: Saves a Dataframe to a file.
        def hash_dump(filename)
          File.binwrite(filename, Marshal.dump(self.to_hash))
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
        #   df = Daru::DataFrame.new( { a: ['a','a','a','b','b'], year: ['2018','2015','2019', '2014', '2013'] })
        #
        #   mymin = lambda do |field, df, group_key, indices|
        #     values = indices.map { |idx| df.row[idx][field] }
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

      refine ::Daru::DataFrame.singleton_class do
        # Public: Creates a DataFrame by reading the dumped version from a file.
        def from_hash_dump(filename)
          ::Daru::DataFrame.new(Marshal.load(File.binread(filename)))
        end
      end
    end
  end
end
