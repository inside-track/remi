require 'remi_spec'

describe Extractor::LocalFile do
  let(:remote_path) { "#{Pathname.new(__FILE__).dirname}" }

  let(:local_file) {
    Extractor::LocalFile.new(
      remote_path: remote_path
    )
  }

  let(:remote_filenames) { Dir[remote_path + '/*'].map { |f| Pathname.new(f).basename.to_s } }

  context '.new' do
    it 'creates an instance with valid parameters' do
      local_file
    end
  end

  context '#all_entires' do
    it 'returns all entries' do
      expect(local_file.all_entries.map(&:name)).to eq remote_filenames
    end
  end

  context '#extract' do
    it 'references local files with the right names' do
      expect(local_file.extract.map { |f| Pathname.new(f).basename.to_s }).to eq remote_filenames
    end
  end
end
