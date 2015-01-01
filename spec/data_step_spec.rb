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

  context 'writing to multiple data sets', skip: 'TODO' do
  end

  context 'sorting data sets', skip: 'TODO' do
  end

  context 'interleaving data sets', skip: 'TODO' do
  end

  context 'merging data sets', skip: 'TODO' do
  end


end
