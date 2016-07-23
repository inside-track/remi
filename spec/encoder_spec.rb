require_relative 'remi_spec'

describe Remi::Encoder do
  let(:field_symbolizer) { double('field_symbolizer') }
  let(:context) { double('context') }
  let(:fields) { double('fields') }
  let(:encoder) { Encoder.new(context: context, fields: fields, field_symbolizer: field_symbolizer) }

  context '#encode' do
    it 'has an encode method' do
      expect(encoder).respond_to? :encode
    end
  end

  context '#field_symbolizer' do
    it 'can be set in the constructor' do
      expect(encoder.field_symbolizer).to eq field_symbolizer
    end

    it 'the field_symbolizer defined in the context takes priority' do
      symbolizer_from_context = double('symbolizer_from_context')
      allow(context).to receive(:field_symbolizer) { symbolizer_from_context }
      expect(encoder.field_symbolizer).to eq symbolizer_from_context
    end
  end

  context '#fields' do
    it 'can be set in the constructor' do
      expect(encoder.fields).to eq fields
    end

    it 'the field_symbolizer defined in the context takes priority' do
      fields_from_context = double('fields_from_context')
      allow(context).to receive(:fields) { fields_from_context }
      expect(encoder.fields).to eq fields_from_context
    end
  end
end
