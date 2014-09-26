require 'remi_spec'

describe Datalibs::CanonicalDatalib do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  let(:mylib) { Datalibs::CanonicalDatalib.new(RemiConfig.work_dirname) }
#  let(:mylib) { Datalibs::CanonicalDatalib.new("#{ENV['HOME']}/Desktop/work") }


  it "is a directory datalib object" do
    expect(mylib).to be_a(Datalibs::CanonicalDatalib)
  end

  it "is initially empty" do
    expect(mylib.length).to eq 0
  end

  it "fails when accessing a non-existent dataset" do
    expect { mylib[:mydata] }.to raise_error(Interfaces::UnknownDataset)
  end

  context "building a new dataset" do
    let(:mydata) { mylib.build(:mydata) }
#    after { mydata.delete }

    it "creates a new dataset" do
      expect { mydata }.to change { mylib.length }.from(0).to(1)
    end

    it "returns a dataset instance" do
      expect(mydata).to be_a(Dataset)
    end
  end

  it "returns an array of dataset names" do
    mylib.build(:mydata1)
    mylib.build(:mydata2)
    expect(mylib.datasets).to match_array([:mydata1, :mydata2])
  end

  context "when a dataset already exists" do
    before { mylib.build(:mydata) }

    it "returns a dataset object when using array accessor" do
      expect(mylib[:mydata]).to be_a(Dataset)
    end

    it "returns a dataset object when using object accessor", skip: "Not sure if I want this" do
      expect(mylib.mydata).to be_a(Dataset)
    end

    it "fails to build a new dataset" do
      expect { mylib.build(:mydata) }.to raise_error Interfaces::DatasetAlreadyExists
    end
  end

end
