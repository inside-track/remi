module Remi
  module DataTarget
    class DataFrame
      include DataSubject

      def initialize(**args)
      end

      def load
        true
      end
    end
  end
end
