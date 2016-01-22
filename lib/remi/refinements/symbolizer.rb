module Remi
  module Refinements
    module Symbolizer
      refine String do
        def symbolize(symbolizer=nil)
          if symbolizer
            symbolizer.call(self)
          else
            Remi::FieldSymbolizers[:standard].call(self)
          end
        end
      end

      refine Symbol do
        def symbolize(symbolizer=nil)
          self.to_s.symbolize
        end
      end
    end
  end
end
