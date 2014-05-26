module Remi

  # Public: Methods in the Datastep module are meant to perform transformation
  # operatons on Dataset objects.
  module Datastep
    include Log
    extend self

    # Creates one or more datasets.
    #
    # dataset - An argument array of datasets that will be created.
    #
    # Returns nothing
    def create(*dataset)
      raise "datastep called, no block given" unless block_given?

      dataset.each do |ds|
        logger.debug "DATASTEP.CREATE> #{ds.name}"
        ds.open_for_write
      end

      yield *dataset
    ensure
      dataset.each do |ds|
        ds.close_and_write_header
      end
    end


    # Reads a datastep.
    #
    # dataset - The dataset instance to be read.
    # by - An ordered array of variable name that define a by-group (default: [])
    #
    # Returns a block
    def read(dataset, by: [])
      logger.debug "DATASET.READ> **#{dataset.name}**"

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


    def sort(in_ds, out: nil, by: [], in_memory: false, split_size: 100000)
      if in_memory
        sort_in_memory(in_ds, out: out, by: by)
        return
      end

      worklib = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

      split_datasets = []
      rows = []
      Datastep.read in_ds do |in_ds|
        if (in_ds._N_ - 1) % split_size == 0
          puts "STARTING A SPLIT"
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

  end
end
