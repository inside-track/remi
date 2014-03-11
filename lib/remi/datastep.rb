module Remi

=begin
  hmmm... datastep only makes sense because I'm a SAS programmer
  perhaps a different name would be appropriate
  the semantic difference between step and read is not clear

  also, the steppers should probably be wrapped up in a class
  should they be class methods of the Dataset class since they act on
  Datasets?

  I could also put the viewer here too

  put each Dataset class method in thier own file, since this class is getting pretty big





  Thinking that the datastep (or whatever I call it) should be the
  thing that gives access to many of the data functions (read and
  define variables should not be able to be called outside of a datastep)


  But still, should data view be part of the Dataset class.  It really doesn't need to
  although it seems more organized if it is.

  Datastep::create work.want do |want|
    Datastep::read work.have do |have|
    end
  end

  Datastep::view work.have



=end


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
