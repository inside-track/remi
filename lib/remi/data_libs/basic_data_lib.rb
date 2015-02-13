module Remi
  module DataLibs

    # Public: The basic data lib defines all of the methods needed
    # for data libs to function with data sets.  Any specific data libs
    # should inherit from this class.  The basic data lib can also be
    # used as a data lib that is a collection of data sets that
    # do not persist data anywhere but memory.
    class BasicDataLib

      # Public: Initialiazes a BasicDataLib.
      def initialize(*args)
      end

      # Public: Returns an array of data set names as symbols.
      #
      # Returns an enumator that iterates over data sets contained in library.
      def data_sets
        update
        library.values
      end

      # Public: Returns the number of data sets currently defined in the library.
      #
      # Returns a number.
      def length
        data_sets.length
      end

      # Public: Used to build and initialize a new data set in this data lib.
      # If a data set already exists, it raises an error.
      #
      # data_set_name - Name of the data set to initialize.
      #
      # Returns a DataSet.
      def build(data_set_name)
        raise Interfaces::DataSetAlreadyExists if interface(data_set_name).data_set_exists?
        build!(data_set_name)
      end

      # Public: Used to build and initialize a new data set in a library.
      # If a data set already exists, it will be overwritten.
      #
      # data_set_name - Name of the data set to initialize.
      #
      # Returns a DataSet.
      def build!(data_set_name)
        interface(data_set_name).create_empty_data_set
        library[data_set_name] = DataSet.new(data_set_name, interface(data_set_name))
      end

      # Public: Array accessor for the DataLib used to retrieve a DataSet.
      #
      # data_set_name - Name of the data set in the library.
      #
      # Returns the DataSet object specified by the name or nil if one does not exist.
      def [](data_set_name)
        library[data_set_name]
      end

      # Public: Deletes a data set from the libary.
      #
      # data_set_name - The name of the data set to delete.
      #
      # Returns nothing.
      def delete(data_set_name)
        library[data_set_name].delete
        library.delete(data_set_name)
      end

      # Public: Updates the list of data sets in a library.  This may be necessary
      # if actions external to the current process create data sets (e.g., another
      # program creates a database table).
      #
      # Returns the hash holding the list of data sets.
      def update
        library
      end

      private


      # Private: library is a hash with keys that are data set names and values
      # that are data set objects.
      #
      # Returns a hash.
      def library
        @library ||= {}
      end

      # Private: Sets the library to a new hash.
      #
      # Returns a hash.
      def library=(value)
        @library = value
      end

      # Private: Builds a BasicInterface for a data set with the specified name
      # in the current DataLib.
      #
      # data_set_name - Name of the data set to build the interface for.
      #
      # Returns a CanonicalInterface.
      def interface(data_set_name)
        Interfaces::BasicInterface.new(self, data_set_name)
      end

    end
  end
end
