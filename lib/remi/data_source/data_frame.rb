module Remi
  module DataSource
    class DataFrame
      include DataSubject

      def initialize(fields: {}, **args)
        @fields = fields
      end

      def df
        @dataframe ||= Daru::DataFrame.new([], order: @fields.keys)
      end

    end
  end
end
