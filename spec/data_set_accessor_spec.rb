require 'remi_spec'

describe DataSetAccessor do
  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { DataLib.new(dir_name: RemiConfig.work_dirname) }
  let(:mydataset) { mylib.build(:mydataset) }


  context 'two datasets with some shared, some different variables' do
    before do
      @ds1 = mylib.build(:ds1)
      @ds2 = mylib.build(:ds2)

      @ds1.define_variables do
        var :common_1
        var :ds1_only
      end

      @ds2.define_variables do
        var :common_1
        var :ds2_only
      end
    end


    shared_examples_for 'common variables' do
      it 'has the common variable' do
        expect(@ds.variable_set.keys).to include :common_1
      end

      it 'creates a new common variable in each data set' do
        expect {
          @ds.define_variables :common_2
        }.to change {
          [:common_2] & @ds1.variable_set.keys & @ds1.variable_set.keys
        }.from([]).to([:common_2])
      end

      it 'sets the value of the common variables in each dataset' do
        expect {
          @ds[:common_1] = 5
        }.to change {
          [@ds1[:common_1], @ds2[:common_1]]
        }.from([nil, nil]).to([5, 5])
      end

      it 'allows the common variable to be reset to something different' do
        expect {
          @ds[:common_1] = 5
          @ds1[:common_1] = 3
        }.to change {
          [@ds1[:common_1], @ds2[:common_1]]
        }.from([nil, nil]).to([3, 5])
      end

      it 'gets the value from the last data set listed' do
        @ds1[:common_1] = 1
        @ds2[:common_1] = 2

        expect(@ds[:common_1]).to eq @ds2[:common_1]
      end

    end

    context 'union accessor' do
      before { @ds = DataSetAccessor.union(@ds1, @ds2) }

      it_behaves_like 'common variables'

      it 'has the difference variables' do
        expect(@ds.variable_set.keys).to include :ds1_only, :ds2_only
      end

      it 'does not create additional variables in the component sets' do
        expect(@ds1.variable_set.keys).not_to include :ds2_only
        expect(@ds2.variable_set.keys).not_to include :ds1_only
      end

      it 'sets the value of difference variables' do
        expect {
          @ds[:ds2_only] = 4
        }.to change {
          @ds2[:ds2_only]
        }.from(nil).to(4)
      end
    end

    context 'intersect accessor' do
      before { @ds = DataSetAccessor.intersect(@ds1, @ds2) }

      it_behaves_like 'common variables'

      it 'does not have the difference variables' do
        expect(@ds.variable_set.keys).not_to include :ds1_only, :ds2_only
      end
    end
  end
end
