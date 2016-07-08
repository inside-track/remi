module Remi
  module DataSource
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

      def stub_number(**attribs)
        Faker::Number.decimal(4,4)
      end

      def stub_float(**attribs)
        Faker::Number.decimal(2,3)
      end

      def stub_decimal(**attribs)
        Faker::Number.decimal(attribs[:precision],attribs[:scale])
      end

      def stub_integer(**attribs)
        Faker::Number.number(4)
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
        end
      end

    end


    class CsvFile
      include DataStub
      def stub_tmp_file
        @stub_tmp_file ||= Tempfile.new('stub_tmp_file.csv').path
      end

      def write_stub_tmp_file
        File.open(stub_tmp_file, "wb") do |file|
          file.puts stub_header
          file.puts stub_row_csv
        end

        stub_tmp_file
      end

      def stub_header
        @fields.keys.join(@csv_options[:col_sep])
      end

      def stub_row_csv
        stub_row_array.join(@csv_options[:col_sep])
      end
    end

    # Hmmm.... this gets called first because I'm trying to split SF off as a "plugin"
    class Salesforce < Remi::DataSubject
      include DataStub
    end

    class DataFrame
      include DataStub
    end

    class Postgres
      include DataStub
    end
  end
end
