module Remi
  module Testing
    module DataStub
      def stub_row_array
        @fields.values.map do |attribs|
          stub_values(attribs)
        end
      end

      def empty_stub_df
        self.df = Daru::DataFrame.new([], order: @fields.keys)
      end

      def stub_df
        empty_stub_df
        self.df.add_row(stub_row_array)
      end

      def stub_values(**attribs)
        stub_type = "stub_#{attribs[:type]}".to_sym
        if respond_to?(stub_type)
          send(stub_type, attribs)
        else
          stub_string(attribs)
        end
      end

      def stub_string(**attribs)
        Faker::Hipster.word
      end

      def stub_float(**attribs)
        Faker::Number.decimal(2,3)
      end

      def stub_decimal(**attribs)
        Faker::Number.decimal(attribs[:precision],attribs[:scale])
      end

      def stub_integer(**attribs)
        Faker::Number.number(4).to_s
      end

      def stub_date(**attribs)
        in_format = attribs[:in_format]
        result = Faker::Date.backward(3650)
        result = result.strftime(in_format) if in_format
        result
      end

      def stub_datetime(**attribs)
        in_format = attribs[:in_format]
        result = Faker::Time.backward(3650)
        result = result.strftime(in_format) if in_format
        result
      end

      def stub_boolean(**attribs)
        ['T','F'].shuffle.first
      end

      def stub_json(**attribs)
        if attribs[:json_array]
          [ stub_string ]
        else
          { Faker::Hipster.words(1, true, true) => stub_string }
        end.to_json
      end

    end
  end
end
