require 'remi_spec'

describe DataLibs::CanonicalDataLib do

  # Reset the work directory before each test
  before { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  let(:mylib) { DataLibs::CanonicalDataLib.new(RemiConfig.work_dirname) }

  it "is a directory data lib object" do
    expect(mylib).to be_a(DataLibs::CanonicalDataLib)
  end

  it "is initially empty" do
    expect(mylib.length).to eq 0
  end

  it "returns nil when accessing a non-existent data set" do
    expect(mylib[:mydata]).to be_nil
  end

  context "building a new data set" do
    let(:mydata) { mylib.build(:mydata) }

    it "creates a new data set" do
      expect { mydata }.to change { mylib.length }.from(0).to(1)
    end

    it "returns a data set instance" do
      expect(mydata).to be_a(DataSet)
    end
  end

  it "returns an array of data set names" do
    mylib.build(:mydata1)
    mylib.build(:mydata2)
    expect(mylib.data_sets).to match_array([mylib[:mydata1], mylib[:mydata2]])
  end

  context "when a data set already exists" do
    before { mylib.build(:mydata) }

    it "returns a data set object when using array accessor" do
      expect(mylib[:mydata]).to be_a(DataSet)
    end

    it "returns a data set object when using object accessor", skip: "Not sure if I want this" do
      expect(mylib.mydata).to be_a(DataSet)
    end

    it "fails to build a new data set" do
      expect { mylib.build(:mydata) }.to raise_error Interfaces::DataSetAlreadyExists
    end

    it "overwrites an existing data set using the bang version" do
      expect { mylib.build!(:mydata) }.not_to raise_error
    end
  end

  context 'deleting a data set' do
    before { mylib.build(:mydata) }

    it 'removes the data set from the library' do
      expect { mylib.delete(:mydata) }.to change { mylib.data_sets.count }.by(-1)
    end
  end

end
