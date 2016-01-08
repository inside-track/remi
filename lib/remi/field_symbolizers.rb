module Remi
  module FieldSymbolizers
    def self.[](symbolizer)
      symbolizers[symbolizer]
    end

    def self.symbolizers
      @symbolizers ||= {
        standard: CSV::HeaderConverters[:symbol],
        salesforce: lambda { |f|
          f.encode(CSV::ConverterEncoding).strip.gsub(/\s+/, "_").
                                           gsub(/\W+/, "").to_sym
        }
      }
    end
  end
end
