require 'remi_spec'

describe Dataset do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { Datalibs::CanonicalDatalib.new(RemiConfig.work_dirname) }
  let(:interface) { Interfaces::CanonicalInterface.new(mylib, 'test') }
  let(:mydataset) { mylib.build(:mydataset) }

  describe 'interacting with variables' do
    before do
      mydataset.define_variables do
        var :myvar
        var :mynumber, type: 'number', format: '%d'
      end
    end

    it 'associates the variables with the dataset' do
      expect(mydataset.variable_set.collect { |k,v| k }).to match_array([:mynumber, :myvar])
    end
    
    it 'does not allow direct assignment of the variable_set' do
      expect { mydataset.variable_set = VariableSet.new }.to raise_error(NoMethodError)
    end

    it 'allows another dataset to inherit the variable from an existing dataset', skip: 'need to get variablesets to accept externally-defined methods' do
      another_dataset = mylib.build(:another_dataset)
      another_dataset.define_variables do |c|
        like mydataset.variable_set
      end
    end
  end



  # Create a new dataset with the canonical interface

  # Define the dataset's variable set

  # Write data to the dataset

  # Read data from the dataset

end
