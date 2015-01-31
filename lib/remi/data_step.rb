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


=begin
    # Used to create data in datasets.  Each dataset listed as an argument
    # is opened for writing at the beginning of the block and is closed
    # at the end.
    #
    # dataset - An argument array of datasets that will be created.
    #
    # Yields a dataset object that is ready for write.
    #
    # Examples
    #   Datastep.create mydataset do |ds|
    #     # ... variable definitions and transforms ...
    #     ds.write_row
    #   end
    #
    # Returns nothing.
    def create(*dataset)
      raise "datastep called, no block given" unless block_given?

      dataset.each do |ds|
        RemiLog.sys.debug "Creating Dataset #{ds.name}"
        ds.open_for_write
      end

      yield *dataset
    ensure
      dataset.each do |ds|
        ds.close_and_write_header
      end
    end


    # Reads a dataset.
    #
    # dataset - The dataset instance to be read.
    # by - An ordered array of variable name that define a by-group (default: [])
    #
    # Returns nothing.
    def read(dataset, by: [])
      RemiLog.sys.debug "Reading Dataset **#{dataset.name}**"

      dataset.open_for_read
      dataset.initialize_by_groups(Array(by)) if Array(by).length > 0

      begin
        while dataset.read_row
          yield dataset
        end
      rescue EOFError
      end

    ensure
      dataset.close
    end


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
