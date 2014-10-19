require 'remi_spec'

describe VariableMeta do

  subject(:example_var) do
    VariableMeta.new do |v|
      v.meta :label     => 'Example variable object'
      v.meta :length    => 18
      v.meta :regex     => /[a-zA-Z0-9]{15,18}/
      v.meta :to_drop   => 'Not important'
    end
  end

  describe 'equivalent ways to define a variable and metadata' do
    let(:refvar) { VariableMeta.new :meta1 => 'Some metadata', :meta2 => 'Some other metadata', :meta3 => 'Yet again' }

    specify 'directly using an array accessor' do
      testvar = VariableMeta.new :meta1 => 'Some metadata', :meta2 => 'Some other metadata'
      testvar[:meta3] = 'Yet again'
      expect(testvar).to eq refvar
    end

    specify 'in a block, using meta method' do
      expect(
        VariableMeta.new do |v|
          v.meta :meta1 => 'Some metadata', :meta2 => 'Some other metadata'
          v.meta :meta3 => 'Yet again'
        end
      ).to eq refvar
    end

    specify 'in a block, using array accessors' do
      expect(
         VariableMeta.new do |v|
           v[:meta1] = 'Some metadata'
           v[:meta2] = 'Some other metadata'
           v[:meta3] = 'Yet again'
         end
      ).to eq refvar
    end
  end

  it 'returns the metadata when referenced using an array accessor' do
    expect(example_var[:label]).to eq 'Example variable object'
  end

  it 'has all of the keys defined (including mandatory)' do
    expect(example_var.keys).to match_array([:length, :label, :regex, :to_drop, :type])
  end

  describe 'mandatory metadata' do
    it 'has the mandatory metadata fields' do
      expect(example_var).to have_key(:type)
    end
    it 'has the default mandatory metadata' do
      expect(example_var[:type]).to eq 'string'
    end
  end

  describe 'importing metadata' do
    let(:derived_example_var) do
      VariableMeta.new do |v|
        v.like example_var
        v.meta :format => '%d'
      end
    end

    it 'has the original metadata' do
      expect(derived_example_var).to include(*example_var.keys)
    end

    it 'has the new metadata too' do
      expect(derived_example_var).to include(:format)
    end
  end

  describe "modifying metadata" do

    shared_examples "surviving metadata" do
      specify { expect(subject).to include(:type, :label, :length, :regex) }
      specify { expect(subject).not_to have_key(:to_drop) }
    end

    context "can be non-destructively dropped" do
      subject(:derived_example_var) { example_var.drop_meta :to_drop }
      specify { derived_example_var; expect(example_var).to have_key(:to_drop) }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively dropped" do
      before { example_var.drop_meta! :to_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be non-destructively kept" do
      subject(:derived_example_var) { example_var.keep_meta :label, :length, :regex }
      specify { derived_example_var; expect(example_var).to have_key(:to_drop) }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively kept" do
      before { example_var.keep_meta! :label, :length, :regex }
      it_behaves_like "surviving metadata"
    end
  end
end
