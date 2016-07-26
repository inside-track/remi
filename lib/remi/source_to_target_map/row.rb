module Remi
  class SourceToTargetMap

    # Public: A row is composed of an array and an index hash.
    # The index hash converts a key into a number representing the position in the array.
    # Functionally, it's very similar to how a hash works.  However,
    # we need to create a lot of Row objects that all have the same
    # index hash.  All of those row objects can reference the same
    # index hash object and thus dramatically reduce the amount of memory
    # needed store a lot of rows.
    #
    # Examples
    #
    #  row = Row.new({ a: 1, b: 2}, ['alpha', 'beta'])
    #  row[:a] #=> 'alpha'
    #  row[:b] #=> 'beta'
    class Row

      # Public: Converts hash-like objects into rows, array-like objects into rows,
      # or just returns a row if one is provied.
      #
      # arg - A Row, array-like object, or hash-like object.
      #
      # Examples:
      #
      #   Row[{ a: 'one', b: 'two' }] #=> #<Row @index={:a=>0, :b=>1} @values=["one", "two"]>
      # Returns a Row
      def self.[](arg)
        return arg if arg.is_a? Row

        if arg.respond_to? :keys
          Row.new(arg.keys.each_with_index.to_h, arg.values)
        else
          Row.new(0.upto(arg.size).each_with_index.to_h, arg)
        end
      end


      # Public: Initializes a row object.
      #
      # index       - A hash containing keys that are usually symbols and values that
      #               represent a position in the values array.
      # values      - An array of values.
      # source_keys - Array of keys that should be treated as data
      #               sources for a row transformation
      def initialize(index, values, source_keys: nil)
        @index = index
        @values = values
        @source_keys = source_keys
      end

      # Public: Returns the value of the row array for the given key
      def [](key)
        @values[@index[key]]
      end

      # Public: Sets the value of the row array for the given key
      def []=(key, value)
        @values[@index[key]] = value
      end

      # Public: Makes Row enumerable, acts like a hash
      def each &block
        return enumerate_row_variables unless block_given?
        enumerate_row_variables.each { |k,v| block.call(k,v) }
      end


      # Public: Enumerates over each source value
      def each_source &block
        Enumerator.new do |y|
          source_keys.each { |key| y << [key, self[key]] }
        end
      end

      # Public: Enumerates over each target value
      def each_target &block
        Enumerator.new do |y|
          target_keys.each { |key| y << [key, self[key]] }
        end
      end

      # Public: Returns the values stored in the row.
      def to_a
        @values
      end

      # Public: Returns the keys of the index.
      def keys
        @index.keys
      end

      # Public: Returns all source keys
      def source_keys
        @source_keys ||= @index.keys
      end

      # Public: Returns all target keys
      def target_keys
        @target_keys ||= keys - source_keys
      end

      private

      def enumerate_row_variables
        inverted_index = @index.invert
        Enumerator.new do |y|
          @values.each_with_index { |value, idx| y << [inverted_index[idx], value] }
        end
      end
    end
  end
end
