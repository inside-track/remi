module Remi

  # Datastep methods operate on Dataset objects
  module Datastep
    include Log

    extend self

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


    def read(dataset,by: [])
      logger.debug "DATASET.READ> **#{dataset.name}**"

      dataset.open_for_read
      dataset.initialize_by_groups(by) if by.length > 0

      puts "Bprev: #{dataset.prev_row}"
      puts "Bcurr: #{dataset.row}"
      puts "Bnext: #{dataset.next_row}"


      begin
        while dataset.read_row
          yield dataset
        end
      rescue EOFError
      end

    ensure
      dataset.close
    end


    def sort(in_ds, out: nil, by: [])
      out_ds = out
      sort_keys = by
      create out_ds do |out_ds|
        Variables.define out_ds do |v|
          v.import in_ds
        end

        rows_with_sort_key = []
        read in_ds do |in_ds|
          rows_with_sort_key << [Array(sort_keys).map {|key| in_ds[key] }, in_ds.row]
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
