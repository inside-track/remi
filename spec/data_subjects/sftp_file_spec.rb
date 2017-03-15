require 'remi_spec'

describe Extractor::SftpFile do
  let(:remote_path) { '' }
  let(:credentials) {
    {
      host: 'host',
      username: 'username',
      password: 'password'
    }
  }

  def generate_extractor
    Extractor::SftpFile.new(
      credentials: credentials,
      remote_path: remote_path
    )
  end

  let(:extractor) { generate_extractor }

  let(:remote_filenames) { ['file1.csv', 'file2.csv'] }

  before do
    allow(extractor).to receive(:begin_connection)

    sftp_session = double('sftp_session')
    allow(extractor).to receive(:sftp_session).and_return(sftp_session)

    sftp_dir = instance_double('Net::SFTP::Operations::Dir')
    allow(sftp_session).to receive(:dir).and_return(sftp_dir)

    allow(sftp_dir).to receive(:entries).and_return(remote_filenames.map { |fname|
      Net::SFTP::Protocol::V04::Name.new(
        fname,
        Net::SFTP::Protocol::V04::Attributes.new(createtime: Time.new.to_i, mtime: Time.new.to_i)
      )
    })
  end

  context '.new' do
    it 'creates an instance with valid parameters' do
      extractor
    end

    it 'requires a hostname' do
      credentials.delete(:host)
      expect { generate_extractor }.to raise_error KeyError
    end

    it 'requires a username' do
      credentials.delete(:username)
      expect { generate_extractor }.to raise_error KeyError
    end

    it 'does not require a password' do # If empty, it will use private keys
      credentials.delete(:password)
      expect { generate_extractor }.not_to raise_error
    end

    it 'defaults to using port 22' do
      expect(extractor.port).to eq '22'
    end

    it 'allows the port to be defined in the credentials' do
      credentials[:port] = '1234'
      expect(generate_extractor.port).to eq '1234'
    end
  end

  context '#all_entires' do
    it 'returns all entries' do
      expect(extractor.all_entries.map(&:name)).to eq remote_filenames
    end
  end

  context '#extract' do
    it 'downloads files from the ftp' do
      expect(extractor.sftp_session).to receive(:download!).exactly(remote_filenames.size).times
      extractor.extract
    end

    it 'creates local files with the right names' do
      allow(extractor.sftp_session).to receive(:download!)
      expect(extractor.extract.map { |f| Pathname.new(f).basename.to_s }).to eq remote_filenames
    end
  end
end


describe Loader::SftpFile do

  let(:credentials) {
    {
      host: 'host',
      username: 'username',
      password: 'password'
    }
  }

  let(:loader) { Loader::SftpFile.new(credentials: credentials, remote_path: 'some_path') }
  let(:data) { double('some_data') }

  before do
    allow(loader).to receive(:begin_connection)

    sftp_session = double('sftp_session')
    allow(loader).to receive(:sftp_session).and_return(sftp_session)
  end

  it 'loads a csv to a target sftp filesystem' do
    expect(loader.sftp_session).to receive(:upload!).with(data, 'some_path')
    loader.load data
  end
end
