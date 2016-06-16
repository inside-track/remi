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

  let(:sftp_file) {
    Extractor::SftpFile.new(
      credentials: credentials,
      remote_path: remote_path
    )
  }

  let(:remote_filenames) { ['file1.csv', 'file2.csv'] }
  let(:sftp_session) { instance_double('Net:SFTP::Session') }

  before do
    sftp_dir = instance_double('Net::SFTP::Operations::Dir')

    allow(Net::SFTP).to receive(:start).and_yield sftp_session
    allow(sftp_session).to receive(:dir).and_return sftp_dir

    allow(sftp_dir).to receive(:entries).and_return(remote_filenames.map { |fname|
      Net::SFTP::Protocol::V04::Name.new(
        fname,
        Net::SFTP::Protocol::V04::Attributes.new(createtime: Time.new.to_i, mtime: Time.new.to_i)
      )
    })
  end

  context '.new' do
    it 'creates an instance with valid parameters' do
      sftp_file
    end

    it 'requires a hostname' do
      credentials.delete(:host)
      expect { sftp_file }.to raise_error KeyError
    end

    it 'requires a username' do
      credentials.delete(:username)
      expect { sftp_file }.to raise_error KeyError
    end

    it 'requires a password' do
      credentials.delete(:password)
      expect { sftp_file }.to raise_error KeyError
    end

    it 'defaults to using port 22' do
      expect(sftp_file.port).to eq '22'
    end

    it 'allows the port to be defined in the credentials' do
      credentials[:port] = '1234'
      expect(sftp_file.port).to eq '1234'
    end
  end

  context '#all_entires' do
    it 'returns all entries' do
      expect(sftp_file.all_entries.map(&:name)).to eq remote_filenames
    end
  end

  context '#extract' do
    it 'downloads files from the ftp' do
      expect(sftp_session).to receive(:download!).exactly(remote_filenames.size).times
      sftp_file.extract
    end

    it 'creates local files with the right names' do
      allow(sftp_session).to receive(:download!)
      expect(sftp_file.extract.map { |f| Pathname.new(f).basename.to_s }).to eq remote_filenames
    end
  end
end
