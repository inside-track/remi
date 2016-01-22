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

        # Public: Saves a Dataframe to a file.
        def hash_dump(filename)
          File.write(filename, Marshal.dump(self.to_hash))
        end

        # Public: Creates a DataFrame by reading the dumped version from a file.
        def self.from_hash_dump(filename)
          ::Daru::DataFrame.new(Marshal.load(File.read(filename)))
        end

        # Public: Allows the user to define an arbitrary aggregation function.
        #
        # by   - The name of the DataFrame vector to use to group records.
        # func - A lambda function that accepts two arguments - the first argument
        #        is the DataFrame and the second is the index of the elements belonging
        #        to a group.
        #
        # Example:
        #   df = Daru::DataFrame.new( { a: ['a','a','a','b','b'], year: ['2018','2015','2019', '2014', '2013'] })
        #
        #   mymin = lambda do |field, df, indicies|
        #     values = indicies.map { |idx| df.row[idx][field] }
        #     values.min
        #   end
        #
        #   df.aggregate(by: :a, func: mymin.curry.(:year))
        #
        #
        # Returns a Daru::Vector.
        def aggregate(by:, func:)
          grouped = self.group_by(by)
          ::Daru::Vector.new(
            grouped.groups.reduce({}) do |h, (key, indicies)|
              h[key.size == 1 ? key.first : key] = func.(self, indicies)
              h
            end
          )
        end

      end
    end
  end
end
