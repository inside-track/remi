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
        @stub_values ||= {
          nil => ->() { Faker::Hipster.word },
          string: ->() { Faker::Hipster.word },
          number: ->() { Faker::Number.decimal(4,4) },
          float: ->() { Faker::Number.decimal(2,2) },
          integer: ->() { Faker::Number.number(4) },
          date: ->() { Date.parse('2015-10-21') }
        }
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

    class Salesforce
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
