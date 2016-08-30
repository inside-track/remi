require_relative 'remi_spec'

describe Remi::Parser do
  let(:field_symbolizer) { double('field_symbolizer') }
  let(:context) { double('context') }
  let(:fields) { double('fields') }
  let(:parser) { Parser.new(context: context, fields: fields, field_symbolizer: field_symbolizer) }

  context '#parse' do
    it 'has a parse method' do
      expect(parser).respond_to? :parse
    end
  end

  context '#field_symbolizer' do
    it 'can be set in the constructor' do
      expect(parser.field_symbolizer).to eq field_symbolizer
    end

    it 'the field_symbolizer defined in the context takes priority' do
      symbolizer_from_context = double('symbolizer_from_context')
      allow(context).to receive(:field_symbolizer) { symbolizer_from_context }
      expect(parser.field_symbolizer).to eq symbolizer_from_context
    end
  end

  context '#fields' do
    it 'can be set in the constructor' do
      expect(parser.fields).to eq fields
    end

    it 'the field_symbolizer defined in the context takes priority' do
      fields_from_context = double('fields_from_context')
      allow(context).to receive(:fields) { fields_from_context }
      expect(parser.fields).to eq fields_from_context
    end
  end
end
