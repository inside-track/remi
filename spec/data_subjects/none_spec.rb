require_relative '../remi_spec'

describe Extractor::None do
  let(:extractor) { Extractor::None.new }

  context '#extract' do
    it 'does nothing' do
      expect(extractor.extract).to be nil
    end
  end
end

describe Parser::None do
  let(:parser) { Parser::None.new }

  context '#parse' do
    it 'returns what it is given' do
      expect(parser.parse('some data')).to eq 'some data'
    end
  end
end

describe Encoder::None do
  let(:encoder) { Encoder::None.new }

  context '#encode' do
    it 'returns what it is given' do
      expect(encoder.encode('some data')).to eq 'some data'
    end
  end
end

describe Loader::None do
  let(:loader) { Loader::None.new }

  context '#loader' do
    it 'does nothing' do
      expect(loader.load('some data')).to be true
    end
  end
end
