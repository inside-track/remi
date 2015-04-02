require 'remi_spec'

describe Interfaces::CanonicalInterface do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }
#P  before { RemiConfig.work_dirname = '/Users/gnilrets/Desktop/work' }

  let(:mylib) { DataLibs::CanonicalDataLib.new(dir_name: RemiConfig.work_dirname) }
  let(:interface) { Interfaces::CanonicalInterface.new(mylib, 'test') }

  describe 'writing the header' do
    before do
      @header_variable_set = VariableSet.new :myvar1, :myvar2
      writer = interface
      writer.open_for_write
      writer.write_metadata(variable_set: @header_variable_set)
      writer.close
    end

    it 'creates a header and detail file' do
      expect(File.exists?(interface.header_file_full_path)).to be true
      expect(File.exists?(interface.data_file_full_path)).to be true
    end

    describe 'reading the header that has been written' do
      before do
        reader = interface
        reader.open_for_read
        @header = reader.read_metadata
        reader.close
      end

      it 'returns the same header that was written' do
        expect(@header[:variable_set]).to eq @header_variable_set
      end

    end

  end

  describe 'writing rows' do
    before do
      @test_data = [ [1,'happy little string',3], [4,'5',6], [7,'8',9] ]

      writer = interface
      writer.open_for_write
      @test_data.each do |row|
        writer.write_row(Row.new(row))
      end
      writer.close
    end

    it 'creates a header and detail file' do
      expect(File.exists?(interface.header_file_full_path)).to be true
      expect(File.exists?(interface.data_file_full_path)).to be true
    end

    describe 'reading rows that have been written' do
      before do
        reader = interface
        reader.open_for_read

        @result_data = []
        @test_data.each do
          row = reader.read_row
          @result_data << { row_data: row.to_a, last_row: row.last_row }
        end
        reader.close
      end

      it 'gives back the same data that was written' do
        expect(@result_data.collect { |r| r[:row_data] }).to eq @test_data
      end

      it 'has the correct eof flags' do
        expect(@result_data.collect { |r| r[:last_row] }).to eq ([false] * (@test_data.length - 1) + [true])
      end
    end
  end
end
