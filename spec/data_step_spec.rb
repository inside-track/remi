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
        expect(ds.first).to eq(ds[:expected_first2]), "expected(attribute1): #{ds[:expected_first2]} \ngot: #{ds.first} \non data row #{ds.row_number}"
        expect(ds.first(:attribute2)).to eq(ds[:expected_first2]), "expected(attribute2): #{ds[:expected_first2]} \ngot: #{ds.first(:attribute2)} \non data row #{ds.row_number}"
      end
    end
  end

  context 'writing to multiple data sets' do
    before do
      DataStep.create mylib.build(:ds1), mylib.build(:ds2) do |ds1,ds2|
        ds = DataSetAccessor.union(ds1,ds2)

        ds.define_variables do
          var :common_same
        end

        ds1.define_variables do
          var :common_different
          var :ds1_only
        end

        ds2.define_variables do
          like ds1, drop: :ds1_only
          var :ds2_only
        end

        ds.define_variables # need to redefine accessor variables

        ds[:common_same] = 'common same'
        ds1[:common_different] = 'different ds1'
        ds2[:common_different] = 'different ds2'
        ds[:ds1_only] = 'ds1 only'
        ds[:ds2_only] = 'ds2 only'

        ds.write_row
      end
    end

    it 'creates multiple data sets' do
      expect(mylib.data_sets.collect { |ds| ds.name }).to match [:ds1, :ds2]
      mylib.data_sets.each do |ds|
        expect(File.exist?(ds.interface.data_file.path)).to be_truthy
      end
    end

    it 'writes the same data to common variables' do
      common_1 = 1
      common_2 = 2

      DataStep.read mylib[:ds1] do |ds|
        common_1 = ds[:common_same]
      end

      DataStep.read mylib[:ds2] do |ds|
        common_2 = ds[:common_same]
      end

      expect(common_1).to eq common_2
    end

    it 'can write different data to common variables' do
      different_1 = nil
      different_2 = nil

      DataStep.read mylib[:ds1] do |ds|
        different_1 = ds[:common_different]
      end

      DataStep.read mylib[:ds2] do |ds|
        different_2 = ds[:common_different]
      end

      expect(different_1).not_to eq different_2
    end

    it 'can write to variables specific to a data set' do
      expect(mylib[:ds1].variable_set).to have_key(:ds1_only)
      expect(mylib[:ds1].variable_set).not_to have_key(:ds2_only)
      expect(mylib[:ds2].variable_set).to have_key(:ds2_only)
      expect(mylib[:ds2].variable_set).not_to have_key(:ds1_only)
    end
  end


  describe 'interleaving data sets' do
    let(:ds1) { mylib.build(:ds1) }
    let(:ds2) { mylib.build(:ds2) }
    let(:ds3) { mylib.build(:ds3) }

    let(:ds1_data) { [] }
    let(:ds2_data) { [] }
    let(:ds3_data) { [] }

    before do
      ds1.define_variables :grp1, :grp2, :val
      ds2.define_variables :grp1, :grp2, :ds2_only, :val
      ds3.define_variables :grp1, :grp2, :val, :ds3_only
    end


    shared_context "data sets to interleave" do
      before do
        DataStep.create ds1 do |ds|
          ds1_data.each do |row|
            ds[:grp1, :grp2, :val] = row
            ds.write_row
          end
        end

        DataStep.create ds2 do |ds|
          ds2_data.each do |row|
            ds[:grp1, :grp2, :ds2_only, :val] = row
            ds.write_row
          end
        end

        DataStep.create ds3 do |ds|
          ds3_data.each do |row|
            ds[:grp1, :grp2, :val, :ds3_only] = row
            ds.write_row
          end
        end
      end
    end

    context 'interleave of two datasets' do
      let(:ds1_data) {
        [
          ['a', 'a', 1],
          ['c', 'c', 3]
        ]
      }

      let(:ds2_data) {
        [
          ['b', 'b', 'ds2', 2]
        ]
      }

      include_context 'data sets to interleave'

      it 'interleaves the rows when by groups are set' do
        expected_result =
          [
            ['a', 'a', 1, nil],
            ['b', 'b', 2, 'ds2'],
            ['c', 'c', 3, nil]
          ]

        result = []
        DataStep.interleave ds1, ds2, by: :grp1 do |dsi|
          result << dsi[:grp1, :grp2, :val, :ds2_only]
        end
        expect(result).to eq expected_result
      end

      it 'interleaves the rows when by groups are not set' do
        expected_result =
          [
            ['a', 'a', 1, nil],
            ['c', 'c', 3, nil],
            ['b', 'b', 2, 'ds2']
          ]

        result = []
        DataStep.interleave ds1, ds2 do |dsi|
          result << dsi[:grp1, :grp2, :val, :ds2_only]
        end
        expect(result).to eq expected_result
      end

      it 'interleaves the rows when by groups are not set by the order listed' do
        expected_result =
          [
            ['b', 'b', 2, 'ds2'],
            ['a', 'a', 1, nil],
            ['c', 'c', 3, nil]
          ]

        result = []
        DataStep.interleave ds2, ds1 do |dsi|
          result << dsi[:grp1, :grp2, :val, :ds2_only]
        end
        expect(result).to eq expected_result
      end
    end

    context 'interleave of two datasets with two by groups' do
      let(:ds1_data) {
        [
          ['B', 'a', 1],
          ['B', 'c', 3],
          ['C', 'b', 5]
        ]
      }

      let(:ds2_data) {
        [
          ['A', 'a', 'ds2', 0],
          ['B', 'b', 'ds2', 2],
          ['C', 'a', 'ds2', 4]
        ]
      }

      include_context 'data sets to interleave'

      it 'interleaves the rows when by groups are set' do
        expected_result =
          [
            ['A', 'a', 0, 'ds2'],
            ['B', 'a', 1, nil],
            ['B', 'b', 2, 'ds2'],
            ['B', 'c', 3, nil],
            ['C', 'a', 4, 'ds2'],
            ['C', 'b', 5, nil]
          ]

        result = []
        DataStep.interleave ds1, ds2, by: [:grp1, :grp2] do |dsi|
          result << dsi[:grp1, :grp2, :val, :ds2_only]
        end
        expect(result).to eq expected_result
      end
    end

    context 'interleave of three datasets with one by group' do
      let(:ds1_data) {
        [
          ['A', 'a', 1],
          ['C', 'c', 4],
          ['D', 'd', 5]
        ]
      }

      let(:ds2_data) {
        [
          ['E', 'a', 'ds2', 6],
          ['F', 'b', 'ds2', 7]
        ]
      }

      let(:ds3_data) {
        [
          ['B', 'b', 2, 'ds3'],
          ['B', 'a', 3, 'ds3']
        ]
      }

      include_context 'data sets to interleave'

      it 'interleaves the rows when by groups are set' do
        expected_result =
          [
            ['A', 'a', 1, nil],
            ['B', 'b', 2, 'ds3'],
            ['B', 'a', 3, 'ds3'],
            ['C', 'c', 4, nil],
            ['D', 'd', 5, nil],
            ['E', 'a', 6, 'ds2'],
            ['F', 'b', 7, 'ds2']
          ]

        result = []
        DataStep.interleave ds1, ds2, ds3, by: :grp1 do |dsi|
          result << dsi[:grp1, :grp2, :val] + [dsi[:ds2_only] || dsi[:ds3_only]]
        end
        expect(result).to eq expected_result
      end
    end
  end


  context 'sorting data sets', skip: 'TODO' do
    it 'does something' do
    end
  end

  context 'merging data sets', skip: 'TODO' do
    it 'does something' do
    end
  end


end
