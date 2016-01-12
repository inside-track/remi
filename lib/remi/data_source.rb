module Remi
  module DataSource
    include DataSubject

    def extract
      raise "Extract function undefined for #{self.class.name}"
    end

    def feild_symbolizer
      Remi::FieldSymbolizers[:standard]
    end
  end
end
