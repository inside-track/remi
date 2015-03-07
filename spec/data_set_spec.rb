require 'remi_spec'

describe DataSet do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { DataLib.new(dir_name: RemiConfig.work_dirname) }
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

  describe 'reading data from a pre-existing dataset' do
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

    it 'reads the header data when it is first opened' do
      newlib = DataLib.new(dir_name: RemiConfig.work_dirname)
      newdataset = newlib[:mydataset]
      expect(newdataset.variable_set.to_yaml).to eq mydataset.variable_set.to_yaml
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

  # We've done more exhaustive by-group testing in row_set_spec.  Here we just
  # need to make sure the interaction with data_sets works.
  describe 'reading data with by groups' do

    let(:groupset) { mylib.build(:groupset) }
    before do
      groupset.define_variables do
        var :group1
        var :group2
        var :expected_first1
        var :expected_last1
        var :expected_first2
        var :expected_last2
      end

      @data_array = [
        ['A','X',true,false,true,true],
        ['A','Y',false,false,true,false],
        ['A','Y',false,true,false,true],
        ['B','Y',true,true,true,true]
      ]

      groupset.open_for_write

      @data_array.each do |row|
        groupset.variable_set.each do |key, var|
          groupset[key] = row[var.index]
        end
        groupset.write_row
      end

      groupset.close
    end

    it 'fails when given bad by group variables' do
      expect { groupset.open_for_read(by_groups: :invalid) }.to raise_error Remi::DataSet::UnknownByGroupVariableError
    end

    context 'open for reading with by groups' do
      before { groupset.open_for_read(by_groups: [:group1, :group2]) }
      after { groupset.close }

      it 'gives the expected first/last indicators' do
        while !groupset.last_row
          groupset.read_row
          expect(groupset.first).to eq groupset[:expected_first2]
          expect(groupset.last).to eq groupset[:expected_last2]
          expect(groupset.first(:group1)).to eq groupset[:expected_first1]
          expect(groupset.last(:group1)).to eq groupset[:expected_last1]
          expect(groupset.first(:group2)).to eq groupset[:expected_first2]
          expect(groupset.last(:group2)).to eq groupset[:expected_last2]
        end
      end
    end
  end

  describe 'setting the value of a row with a data set as an argument' do
    let(:ds1) { mylib.build(:ds1) }
    let(:ds2) { mylib.build(:ds2) }

    before do
      ds1.define_variables :var1, :var2, :var3, :var_ds1
      ds2.define_variables :var1, :var2, :var3, :var_ds2

      ds1[:var1] = 'ds1 var1'
      ds1[:var2] = 'ds1 var2'
      ds1[:var3] = 'ds1 var3'
      ds1[:var_ds1] = 'ds1 var_ds1'

      ds2[:var1] = 'ds2 var1'
      ds2[:var2] = 'ds2 var2'
      ds2[:var3] = 'ds2 var3'
      ds2[:var_ds2] = 'ds2 var_ds2'
    end

    it '[]= assigns all common variables' do
      expect { ds1[] = ds2 }.to change { ds1[:var1, :var2] }.to(ds2[:var1, :var2])
    end

    it '[:key1]= assigns only specified keys' do
      expect { ds1[:var1] = ds2 }.to change { ds1[:var1, :var2] }.to([ds2[:var1], ds1[:var2]])
    end

    it '[:key1,:key2]= assigns only specified keys' do
      expect { ds1[:var1,:var3] = ds2 }.to change { ds1[:var1, :var2, :var3] }.to([ds2[:var1], ds1[:var2], ds2[:var3]])
    end

    it 'does not change variable if they are not in the target set' do
      expect { ds1[:var_ds1] = ds2 }.not_to change { ds1.row_to_a }
    end
  end
end
