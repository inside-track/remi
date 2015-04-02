require 'remi_spec'

describe Interfaces::DelimitedTextInterface do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  let(:dir_path) { RemiConfig.work_dirname }

  let(:mylib) {
    DataLib.new(:delimited_text,
                dir_name: dir_path,
                csv_opt: {
                  col_sep: '|'
                }
               )
  }

  let(:test_file_name) { 'test.csv' }
  let(:test_file_path) { "#{dir_path}/#{test_file_name}" }
  let(:interface) { Interfaces::DelimitedTextInterface.new(mylib, test_file_name) }


  context 'with an existing delimited file' do

    context 'with a header record' do
      before do
        File.write(test_file_path, <<-EOF.unindent
          csvattr|csvvalue
          Alpha|1
          Beta|2
          Gamma|3
          EOF
        )
      end

      context 'using the header record' do
        let(:mylib) {
          DataLib.new(:delimited_text,
                      dir_name: dir_path,
                      header_as_variables: true,
                      csv_opt: {
                        col_sep: '|'
                      }
                     )
        }

        before do
          interface.read_metadata
          interface.open_for_read
        end

        after { interface.close }


        it 'reads the header into a variable set' do
          expect(interface.read_metadata[:variable_set]).to include(:csvattr, :csvvalue)
        end

        it 'reads the first row of data' do
          row = interface.read_row
          expect([row[:csvattr], row[:csvvalue]]).to eq ['Alpha', '1']
        end

        it 'reads the correct number of source data rows' do
          values = []
          loop do
            values << interface.read_row[:csvvalue]
            break if interface.eof_flag
          end
          expect(values).to eq ['1', '2', '3']
        end
      end

      context 'not using the header record' do
        let(:mylib) {
          DataLib.new(:delimited_text,
                      dir_name: dir_path,
                      header_as_variables: false,
                      csv_opt: {
                        col_sep: '|'
                      }
                     )
        }

        it 'returns an empty variable set for metadata' do
          expect(interface.read_metadata[:variable_set].size).to eq 0
        end

        it 'fails to load rows using the header' do
          variable_set = interface.read_metadata[:variable_set]

          interface.open_for_read
          row = interface.read_row
          interface.close

          expect { row[:csvattr] }.to raise_error(Row::UnknownVariableKeyError)
        end

        it 'uses csv_opt in the variable_set metadata to load colums' do
          variable_set = VariableSet.new do
            var :myvalue, csv_opt: { col: 2 }
            var :mydummy
            var :myattr, csv_opt: { col: 1 }
          end

          interface.open_for_read
          interface.set_key_map(variable_set)
          row = interface.read_row
          interface.close

          expect([row[:myvalue], row[:mydummy], row[:myattr]]).to eq ['1', nil, 'Alpha']
        end
      end
    end

    context 'without a header record' do
      let(:mylib) {
        DataLib.new(:delimited_text,
                    dir_name: dir_path,
                    csv_opt: {
                      headers: false,
                      col_sep: '|'
                    }
                   )
      }
      before do
        File.write(interface.data_file_full_path, <<-EOF.unindent
          Alpha|1
          Beta|2
          Gamma|3
          EOF
        )
      end

      it 'returns an empty variable set for metadata' do
        expect(interface.read_metadata[:variable_set].size).to eq 0
      end

      it 'uses csv_opt in the variable_set metadata to load colums' do
        variable_set = VariableSet.new do
          var :myvalue, csv_opt: { col: 2 }
          var :mydummy
          var :myattr, csv_opt: { col: 1 }
        end

        interface.open_for_read
        interface.set_key_map variable_set
        row = interface.read_row
        interface.close

        expect([row[:myvalue], row[:mydummy], row[:myattr]]).to eq ['1', nil, 'Alpha']
      end
    end
  end


  describe 'writing delimited data' do
    shared_context 'a file is written' do
      before do
        @variable_set = VariableSet.new do
          var :myattr, csv_opt: { col: 1 }
          var :myvalue, csv_opt: { col: 2 }
        end

        interface.open_for_write
        interface.write_metadata(variable_set: @variable_set)
        interface.write_row(Row.new(['Alpha','1']))
        interface.close
      end
    end

    context 'when header is specified to be written' do
      let(:mylib) {
        DataLib.new(:delimited_text, dir_name: dir_path,
                    header_as_variables: true
                   )
      }

      include_context 'a file is written'

      it 'writes a header using the labels in all variables in the set' do
        variable_set = interface.read_metadata[:variable_set]
        expect(variable_set.keys).to eq [:myattr, :myvalue]
      end

      it 'writes data to the file' do
        variable_set = interface.read_metadata[:variable_set]

        interface.open_for_read
        row = interface.read_row
        interface.close

        expect([row[:myattr], row[:myvalue]]).to eq ['Alpha', '1']
      end
    end

    context 'when header is specified not to be written' do
      let(:mylib) {
        DataLib.new(:delimited_text, dir_name: dir_path,
                    header_as_variables: true,
                    csv_opt: {
                      headers: false
                    }
                   )
      }

      include_context 'a file is written'

      it 'doesn\'t write a header' do
        variable_set = interface.read_metadata[:variable_set]
        expect(variable_set.size).to eq 0
      end

      it 'writes data to the file' do
        interface.open_for_read
        interface.set_key_map @variable_set
        row = interface.read_row
        interface.close

        expect([row[:myattr], row[:myvalue]]).to eq ['Alpha', '1']
      end
    end
  end
end
