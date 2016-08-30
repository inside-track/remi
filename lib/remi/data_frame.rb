module Remi
  module DataFrame
    class << self
      def create(df_type = :daru, *args, **kargs, &block)
        dataframe = case df_type
          when :daru
            Remi::DataFrame::Daru.new(*args, **kargs, &block)
          else
            raise TypeError, "Unknown frame type: #{df_type}"
          end
      end

      def daru(*args, **kargs, &block)
        self.create(:daru, *args, **kargs, &block)
      end
    end


    def [](*args)
      super
    end

    def size
      super
    end

    def write_csv(*args, **kargs, &block)
      super
    end

    # Public: Returns the type of DataFrame
    def df_type
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end
  end
end
