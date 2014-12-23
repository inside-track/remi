require 'remi_spec'

describe Dataset do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  # Test using the canonical library and interface
  let(:mylib) { Datalibs::CanonicalDatalib.new(RemiConfig.work_dirname) }
  let(:interface) { Interfaces::CanonicalInterface.new(mylib, 'test') }
  let(:mydataset) { mylib.build(:mydataset) }

  it 'does something' do
    mydataset.variable_set.define do
      var :myvar
      var :anothervar
    end

    puts mydataset.variable_set.collect { |k,v| v.to_hash }

  end


  # Create a new dataset with the canonical interface

  # Define the dataset's variable set

  # Write data to the dataset

  # Read data from the dataset

end
