require 'remi_spec'

describe Dataset do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { Datalib.new(dir_name: RemiConfig.work_dirname) }
  let(:mydataset) { mylib.build(:mydataset) }


  before do
    mydataset.define_variables do
      var :myvar
      var :mynumber, type: 'number', format: '%d'
    end
  end

  describe 'interacting with variables' do
    it 'associates the variables with the dataset' do
      expect(mydataset.variable_set.collect { |k,v| k }).to match_array([:mynumber, :myvar])
    end

    it 'does not allow direct assignment of the variable_set' do
      expect { mydataset.variable_set = VariableSet.new }.to raise_error(NoMethodError)
    end

    it 'allows another dataset to inherit the variable from an existing dataset' do
      another_dataset = mylib.build(:another_dataset)
      another_dataset.define_variables do
        like mydataset.variable_set
      end
      expect(another_dataset.variable_set).to eq mydataset.variable_set
    end
  end

  describe 'creating data' do
    before do
      mydataset.open_for_write

      mydataset[:myvar] = 'Alpha'
      mydataset[:mynumber] = 42
    end

    after { mydataset.close }

    it 'sets the value of a variable that can then be recalled' do
      expect(mydataset[:myvar]).to eq 'Alpha'
      expect(mydataset[:mynumber]).to eq 42
    end

    context 'after writing the row' do
      before { mydataset.write_row }

      it 'retains the value of the variable' do
        expect(mydataset[:myvar]).to eq 'Alpha'
      end

      it 'allows the current value of the variable to be modified' do
        mydataset[:myvar] = 'Beta'
        expect(mydataset[:myvar]).to eq 'Beta'
      end

      it 'allows recovery of the previous value of the variable' do
        mydataset[:myvar] = 'Beta'
        expect(mydataset.lag(1)[:myvar]).to eq 'Alpha'
      end
    end
  end

  describe 'reading data from rows' do
    before do
      @data_array = [ ['Row1', 1], ['Row2', 2] ]

      mydataset.open_for_write

      @data_array.each do |row|
        mydataset[:myvar] = row[0]
        mydataset[:mynumber] = row[1]
        mydataset.write_row
      end

      mydataset.close
    end

    it 'reads the data that has been written' do
      mydataset.open_for_read

      while !mydataset.last_row
        mydataset.read_row
        expect(mydataset[:myvar]).to eq @data_array[mydataset.row_number - 1][0]
        expect(mydataset[:mynumber]).to eq @data_array[mydataset.row_number - 1][1]
      end

      mydataset.close
    end
  end
end
