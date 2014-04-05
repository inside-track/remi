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


    def read(dataset)
      logger.debug "DATASET.READ> **#{dataset.name}**"

      dataset.open_for_read

      begin
        while dataset.read_row
          yield dataset
        end
      rescue EOFError
      end

    ensure
      dataset.close
    end
  end
end
