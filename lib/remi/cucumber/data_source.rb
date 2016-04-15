module Remi
  module DataSource
    module DataStub
      def stub_row_array
        @fields.values.map do |attrib|
          stub_values[attrib[:type]].call
        end
      end

      def empty_stub_df
        self.df = Daru::DataFrame.new([], order: @fields.keys)
      end

      def stub_df
        empty_stub_df
        self.df.add_row(stub_row_array)
      end

      def stub_values
        @stub_values ||= Hash.new(->() { Faker::Hipster.word }).merge({
          string:   ->() { Faker::Hipster.word },
          number:   ->() { Faker::Number.decimal(4,4) },
          float:    ->() { Faker::Number.decimal(2,2) },
          integer:  ->() { Faker::Number.number(4) },
          date:     ->() { Faker::Date.backward(3650) },
          datetime: ->() { Faker::Time.backward(3650).to_datetime },
          boolean:  ->() { ['T','F'].shuffle.first }
        })
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
