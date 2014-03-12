module Remi

  # Datastep methods operate on Dataset objects
  module Datastep
    include Log

    extend self

    def create(*dataset)
      raise "datastep called, no block given" if not block_given?

      logger.debug "DATASTEP> #{dataset}"

      dataset.each do |ds|
        ds.open_for_write
      end

      yield *dataset
    ensure
      dataset.each do |ds|
        ds.close_and_write_header
      end
    end


    def read(dataset)
      logger.debug "DATASET.READ> **#{dataset.name}**"

      dataset.open_for_read

      begin
        while dataset.readrow
          yield dataset
        end
      rescue EOFError
      end

    ensure
      dataset.close
    end
  end
end
