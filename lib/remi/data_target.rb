module Remi
  module DataTarget
    include DataSubject

    # Gets called automatically at the end of a job, but could
    # also get manually called at the end of a transform so make
    # sure it doesn't do it twice.
    def load
      @logger.info "Loading target"
      return true if @loaded
      @loaded = true
      raise "Load function undefined for #{self.class.name}"
    end
  end
end
