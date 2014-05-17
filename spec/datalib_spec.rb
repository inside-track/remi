require 'remi_spec'

describe Datalib do
  before { @work = Datalib.new :directory => { :dirname => RemiConfig.work_dirname } }
  subject { @work }

  it "should create a datalib" do
    should be_a_kind_of(Datalib)
  end

  it "should read all existing dataset metadata into memory" do
  end
end
