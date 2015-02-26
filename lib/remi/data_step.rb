module Remi

  # Public: Methods in the DataStep module are meant to perform transformation
  # operatons on DataSet objects.
  module DataStep
    extend self


    # Used to create data in data sets.  Each data set listed as an argument
    # is opened for writing at the beginning of the block and is closed
    # at the end.
    #
    # data_set - An argument array of data sets that will be created.
    #
    # Yields a DataSet object that is ready for write.
    #
    # Examples
    #   DataStep.create mydataset do |ds|
    #     # ... variable definitions and transforms ...
    #     ds.write_row
    #   end
    #
    # Returns nothing.
    def create(*data_sets)
      raise "DataStep.create called, no block given" unless block_given?

      data_sets.each do |ds|
        RemiLog.sys.debug "Creating DataSet #{ds.name}"
        ds.open_for_write
      end

      begin
        yield *data_sets
      ensure
        data_sets.each do |ds|
          ds.close
        end
      end
    end


    # Public: Used to read a data_set.
    #
    # data_set - The data_set instance to be read.
    # by - An ordered array of variable names that define a by-group (default: [])
    #
    # Examples
    #
    #  Example goes here
    #
    # Returns nothing.
    def read(data_set, by: [])
      RemiLog.sys.debug "Reading Dataset **#{data_set.name}**"

      data_set.open_for_read(by_groups: Array(by))

      begin
        while !data_set.last_row
          data_set.read_row
          yield data_set
        end
      ensure
        data_set.close
      end
    end


    # Public: Used to interleave multiple data sets.
    #
    # *data_sets - An array list of datasets to interleave.
    # by         - An optional array of the by-group variable names to use to interleave the datasets.
    #              If no by-group is given, data sets are stacked in the order given.
    # Examples
    #
    #  Example goes here
    #
    # Returns nothing.
    def interleave(*data_sets, by: [])
      by_groups = Array(by)

      by_group_values = lambda { |ds| by_groups == [] ? [0] : by_groups.map { |key| ds[key] } }


      # Create a basic dataset to hold a row for the result of the interleave
      worklib = DataLib.new(:basic)

      data_sets.each do |ds|
        ds.open_for_read(by_groups: by_groups)
      end

      # Create variables needed to hold the result of the interleave
      dsi = worklib.build(:dsi)
      dsi.define_variables do
        data_sets.each do |ds|
          var :__ORIGIN_NAME__
          var :__ORIGIN_ID__
          like ds
        end
      end
      dsi.open_for_read

      # Array to help figure out which data set to read from next
      next_data_set = []
      data_sets.each do |ds|
        ds.read_row
        next_data_set << [ds, by_group_values.call(ds)]
      end

      while next_data_set.size != 0 do

        # Determine the next data set to read
        next_data_set.sort! do |a,b|
          result = nil
          a[1].zip(b[1]).each do |va, vb|
            result = (va <=> vb)
            break unless result == 0
          end
          result
        end


        # Read the next data set until the end of the by group
        ds = next_data_set.shift[0]
        first_read = true
        loop do
          ds.read_row unless first_read
          first_read = false

          dsi.read_row
          dsi[:__ORIGIN_NAME__] = ds.name
          dsi[:__ORIGIN_ID__] = ds.object_id
          dsi[] = ds

          yield dsi

          break if ds.last || ds.last_row
        end

        # Read the next row of the data set just read to determine which set to read next
        unless ds.last_row
          ds.read_row
          next_data_set << [ds, by_group_values.call(ds)]
        end
      end

    ensure
      data_sets.each do |ds|
        ds.close
      end
    end



    # Public: Used to sort data sets.
    #
    # in_ds      - The input dataset to be sorted.
    # by         - An array of variable names that form the by-group to be sorted.
    # in_memory  - Force the sort to happen in-memory (default: false).
    # split_size - The maximum number of rows allowed in memory for sorting (default: RemiConfig.sort.split_size).
    #
    # Examples
    #
    #  DataStep.sort unsorted_ds, out: sorted_ds, by: [:grp1, :grp2]
    #
    # Returns nothing.
    def sort(in_ds, out:, by:, in_memory: false, split_size: RemiConfig.sort.split_size)
      if in_memory
        DataStepHelper.sort_in_memory(in_ds, out: out, by: by)
      else
        DataStepHelper.sort_external(in_ds, out: out, by: by, split_size: split_size)
      end
    end


    # Private: Class holding methods helpful to data step operations but are
    # not intended to be used by external methods or classes.
    class DataStepHelper

      # Private: Accepts an array with a row and a sort key and writes a
      # a data set sorted by the sort keys.
      #
      # rows_with_sort_key - Expects an array with two elements.  The first element
      #                      is an array of keys that define the sort order.  The second
      #                      is an array of row values.
      # variable_set       - The variable set to use for the output data set.
      # out_ds             - The output data set to write.
      #
      # Returns nothing.
      def self.sort_rows_and_write_dataset(rows_with_sort_key, variable_set:, out_ds:)
        DataStep.create out_ds do |out_ds|
          out_ds.define_variables do
            like variable_set
          end

          rows_with_sort_key.sort! do |a,b|
            result = nil
            a[0].zip(b[0]).each do |va,vb|
              result = (va <=> vb)
              break unless result == 0
            end
            result
          end

          rows_with_sort_key.each do |row_with_sort_key|
            out_ds[] = row_with_sort_key[1]
            out_ds.write_row
          end
        end
      end

      # Private: Sorts a data set in memory.
      #
      # in_ds - Input data set to sort.
      # out   - Output data set to write.
      # by    - Data set is sorted by these keys (array of variable names).
      #
      # Returns nothing.
      def self.sort_in_memory(in_ds, out:, by:)
        sort_keys = Array(by)

        rows_with_sort_key = []
        DataStep.read in_ds do |in_ds|
          rows_with_sort_key << [sort_keys.map { |key| in_ds[key] }, in_ds[]]
        end

        sort_rows_and_write_dataset(rows_with_sort_key, variable_set: in_ds.variable_set, out_ds: out)

        nil
      end

      # Private: Sorts a data set using an external sort algorithm.
      #
      # in_ds      - Input data set to sort.
      # out        - Output data set to write.
      # by         - Data set is sorted by these keys (array of variable names).
      # split_size - The maximum number of rows to hold in memory for sorting.
      #
      # Returns nothing.
      def self.sort_external(in_ds, out:, by:, split_size: RemiConfig.sort.split_size)
        sort_keys = Array(by)
        out_ds = out

        worklib = DataLib.new(dir_name: RemiConfig.system_work_dirname)

        split_datasets = []
        rows_with_sort_key = []
        DataStep.read in_ds do |in_ds|
          rows_with_sort_key = [] if (in_ds.row_number - 1) % split_size == 0

          rows_with_sort_key << [sort_keys.map { |key| in_ds[key] }, in_ds[]]

          if in_ds.row_number % split_size == 0 || in_ds.last_row
            split_datasets << worklib.build("#{out_ds.name}-#{split_datasets.size}".to_sym)
            sort_rows_and_write_dataset(rows_with_sort_key, variable_set: in_ds.variable_set, out_ds: split_datasets.last)
          end
        end

        DataStep.create out_ds do |out_ds|
          out_ds.define_variables do
            like in_ds
          end

          DataStep.interleave *split_datasets, by: sort_keys do |dsi|
            out_ds[] = dsi
            out_ds.write_row
          end
        end
      end
    end
  end
end
