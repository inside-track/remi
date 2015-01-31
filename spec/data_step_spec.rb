require 'remi_spec'

describe DataStep do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { DataLib.new(dir_name: RemiConfig.work_dirname) }


  context 'simple read of an existing data set' do

    let(:example_data) {
      [
        ['A','X',true,true,8],
        ['B','X',true,true,1],
        ['B','Y',false,true,5],
        ['B','Y',false,false,3]
      ]
    }

    before do
      DataStep.create mylib.build(:mydataset) do |ds|
        ds.define_variables do
          var :attribute1
          var :attribute2
          var :expected_first1
          var :expected_first2
          var :value
        end

        example_data.each do |row|
          ds.variable_set.each do |key, var|
            ds[key] = row[var.index]
          end
          ds.write_row
        end
      end
    end

    it 'reads data that has been written' do
      counter_total = 0
      DataStep.read mylib[:mydataset] do |ds|
        counter_total += ds.row_number
      end

      expect(counter_total).to eq example_data.size * (example_data.size + 1)/2
    end

    it 'can make use of by groups' do
      DataStep.read mylib[:mydataset], by: [:attribute1, :attribute2] do |ds|
        expect(ds.first).to eq(ds[:expected_first1]), "expected(attribute1): #{ds[:expected_first1]} \ngot: #{ds.first} \non data row #{ds.row_number}"
        expect(ds.first(:attribute2)).to eq(ds[:expected_first2]), "expected(attribute2): #{ds[:expected_first2]} \ngot: #{ds.first(:attribute2)} \non data row #{ds.row_number}"
      end
    end
  end

  context 'writing to multiple data sets' do
    before do
      DataStep.create mylib.build(:ds1), mylib.build(:ds2) do |ds1,ds2|
        #        ds = DataStep.conjoined(ds1,ds2)
        ds = ConjoinedDataSet.new(ds1,ds2)

        ds.define_variables do
          var :common_var
        end

        ds1.define_variables do
          var :different_var
          var :ds1_var
        end

        ds2.define_variables do
          like ds1, drop: :ds1_var
          var :ds2_var
        end

        ds[:common_var] = "same"
        ds1[:different_var] = "version 1"
        ds2[:different_var] = "version 2"
        ds[:ds1_var] = "only in 1"
        ds[:ds2_var] = "only in 2"

        ds.write_row
      end
    end

    it 'creates multiple datasets' do
      # How do I write an expectation that a data set exists?  May need to
      # extend the library function.
    end

    it 'writes the same data to common variables' do
      common_var_1 = nil
      common_var_2 = nil

      DataStep.read mylib[:ds1] do |ds|
        common_var_1 = ds[:common_var]
      end

      DataStep.read mylib[:ds2] do |ds|
        common_var_2 = ds[:common_var]
      end

      expect(common_var_1).to eq common_var_2
    end

    it 'can write different data to common variables' do
      different_var_1 = nil
      different_var_2 = nil

      DataStep.read mylib[:ds1] do |ds|
        different_var_1 = ds[:different_var]
      end

      DataStep.read mylib[:ds2] do |ds|
        different_var_2 = ds[:different_var]
      end

      expect(different_var_1).not_to eq different_var_2
    end

    it 'can write to variables specific to a data set' do
      expect(mylib[:ds1]).to have_variable(:ds1_var)
      expect(mylib[:ds1]).not_to have_variable(:ds2_var)
      expect(mylib[:ds2]).to have_variable(:ds2_var)
      expect(mylib[:ds2]).not_to have_variable(:ds1_var)
    end
  end

  context 'sorting data sets', skip: 'TODO' do
    it 'does something' do
    end
  end

  context 'interleaving data sets', skip: 'TODO' do
    it 'does something' do
    end
  end

  context 'merging data sets', skip: 'TODO' do
    it 'does something' do
    end
  end


end
