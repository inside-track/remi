require_relative 'remi_spec'

describe Remi::Loader do
  let(:loader) { Loader.new }

  context '#load' do
    it 'has a load method' do
      expect(loader).respond_to? :load
    end
  end
end
