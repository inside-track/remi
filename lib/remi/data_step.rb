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


    # Reads a data_set.
    #
    # data_set - The data_set instance to be read.
    # by - An ordered array of variable name that define a by-group (default: [])
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

=begin


    def sort(in_ds, out: nil, by: [], in_memory: false, split_size: RemiConfig.sort.split_size)
      if in_memory
        sort_in_memory(in_ds, out: out, by: by)
        return
      end

      worklib = DataLib.new :directory => {:dirname => RemiConfig.work_dirname}

      split_datasets = []
      rows = []
      Datastep.read in_ds do |in_ds|
        if (in_ds._N_ - 1) % split_size == 0
          rows = []
        end

        rows << in_ds.row


        if in_ds._N_ % split_size == 0 || in_ds.next_EOF
          split_datasets << worklib.send("split_#{split_datasets.length}".to_sym)

          Datastep.create split_datasets[-1] do |split_ds|
            Variables.define split_ds do |v|
              v.import in_ds
            end

            rows.each do |row|
              split_ds.row = row
              split_ds.write_row
            end
          end
        end
      end


      sorted_datasets = []
      split_datasets.each_with_index do |ds,i|
        sorted_datasets << worklib.send("split_sort_#{i}".to_sym)
        sort_in_memory(ds, out: sorted_datasets[-1], by: by)
      end


      Datastep.create out do |ds|
        Variables.define ds do |v|
          v.import in_ds
        end

        Datastep.interleave *sorted_datasets, by: by do |dsi|
          ds.read_row_from dsi
          ds.write_row
        end
      end
    end


    def sort_in_memory(in_ds, out: nil, by: [])
      out_ds = out
      sort_keys = Array(by)
      Datastep.create out_ds do |out_ds|
        Variables.define out_ds do |v|
          v.import in_ds
        end

        rows_with_sort_key = []
        Datastep.read in_ds do |in_ds|
          rows_with_sort_key << [sort_keys.map { |key| in_ds[key] }, in_ds.row]
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
          out_ds.row = row_with_sort_key[1]
          out_ds.write_row
        end
      end
    end

    def merge
    end
=end
  end
end
