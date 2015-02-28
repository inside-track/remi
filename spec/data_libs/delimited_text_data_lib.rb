require 'remi_spec'

describe DataLibs::DelimitedTextDataLib do

  # Reset the work directory before each test
  let(:workdir) { RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir) }

  #  let(:mylib) { DataLibs::DelimitedTextDataLib.new(RemiConfig.work_dirname) }
  let(:mylib) { DataLib.new(:delimited_text, dir_name: RemiConfig.work_dirname) }

  it "is a delimited text data lib object" do
    expect(mylib.data_lib_type).to eq DataLibs::DelimitedTextDataLib.name
  end

  it "is initially empty" do
    expect(mylib.length).to eq 0
  end

  it "returns nil when accessing a non-existent data set" do
    expect(mylib[:mydata]).to be_nil
  end

  context 'detecting text files' do
    let(:dummy_files) { ['keep-test1.csv', 'keep-test2.csv', 'drop-test3.csv', 'drop-test4.txt'] }

    before do
      dummy_files.each do |f|
        FileUtils.touch("#{workdir}/#{f}")
      end
    end

    it 'contains some files' do
      expect(mylib.data_sets.size).to_not be 0
    end
    it 'contains all files by default' do
      expect(mylib.data_sets.collect { |ds| ds.name }).to match_array dummy_files.collect { |f| f.to_sym }
    end

    it 'contains only files matching a pattern' do
      pattern = /\Akeep-.*\.csv/
      keeplib = DataLib.new(:delimited_text, dir_name: workdir, file_pattern: pattern)
      expect(keeplib.data_sets.collect { |ds| ds.name.to_s}).to match dummy_files.select { |f| f.match(pattern) }
    end
  end

end


=begin

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
=end
