require_relative 'remi_spec'

describe Remi::Extractor do
  let(:extractor) { Extractor.new }

  context '#extract' do
    it 'has an extract method' do
      expect(extractor).respond_to? :extract
    end
  end
end
