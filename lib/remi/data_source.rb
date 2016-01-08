module Remi
  module DataSource
    include DataSubject

    def extract
      raise "Extract function undefined for #{self.class.name}"
    end
  end
end
