require 'remi_spec'

describe VariableSet do

  # Pre-define some variables to be used in variableset tests
  let(:shared_vars) do
    {
      :account_id => (VariableMeta.new :length => 18, :label => "Account Id"),
      :name       => (VariableMeta.new :length => 80, :label => "Account Name")
    }
  end

  subject(:example_set) { VariableSet.new :account_id => shared_vars[:account_id], :name => shared_vars[:name], :balance => { :type => 'currency' } }

  describe 'equivalent ways to define a variable set' do
    specify 'directly using an array accesor' do
      testset = VariableSet.new 
      testset[:account_id] = shared_vars[:account_id]
      testset[:name]       = shared_vars[:name]
      testset[:balance]    = { :type => 'currency' }
      expect(testset).to eq example_set
    end

    specify 'in a block, using the var method' do
      expect(
        VariableSet.new do |v|
          v.var :account_id, shared_vars[:account_id]
          v.var :name,       shared_vars[:name]
          v.var :balance,    { :type => 'currency' }
        end
      ).to eq example_set
    end

    specify 'in a block, using array accessors' do
      expect(
        VariableSet.new do |v|
          v[:account_id] = shared_vars[:account_id]
          v[:name]       = shared_vars[:name]
          v[:balance]    = { :type => 'currency' }
        end
      ).to eq example_set
    end
  end

  it 'returns a variable when referenced using an array accessor' do
    expect(example_set[:name].meta).to eq shared_vars[:name]
  end

  it 'has all of the keys defined' do
    expect(example_set.keys).to match_array([:name, :account_id, :balance])
  end

  describe 'importing variable sets' do
    let(:derived_set) do
      VariableSet.new do |v|
        v.like example_set
        v.var :group
      end
    end

    it 'has the original set of variables' do
      expect(derived_set).to include(*example_set.keys)
    end

    it 'has the new variable too' do
      expect(derived_set).to include(:group)
    end
  end

  describe 'modifying variable sets' do
    subject(:original_set) do
      VariableSet.new do |v|
        v.like example_set
        v.var :to_drop
        v.var :to_also_drop
      end
    end

    shared_examples "surviving variables" do
      specify { expect(subject).to include(:account_id, :name, :balance) }
      specify { expect(subject).not_to include(:to_drop, :to_also_drop) }
    end

    context "can be non-destructively dropped" do
      subject(:modified_set) { original_set.drop_vars :to_drop, :to_also_drop }
      specify { modified_set; expect(original_set).to include(:to_drop, :to_also_drop) }
      it_behaves_like "surviving variables"
    end

    context "can be destructively dropped" do
      before { original_set.drop_vars! :to_drop, :to_also_drop }
      it_behaves_like "surviving variables"
    end

    context "can be non-destructively kept" do
      subject(:modified_set) { original_set.keep_vars :account_id, :name, :balance }
      specify { modified_set; expect(original_set).to include(:to_drop, :to_also_drop) }
      it_behaves_like "surviving variables"
    end

    context "can be destructively kept" do
      before { original_set.keep_vars! :account_id, :name, :balance }
      it_behaves_like "surviving variables"
    end
  end

  describe "how variables are ordered" do
    it 'increments the index when a variable is added' do
      original_size = example_set.size

      example_set.modify do |v|
        v.var :premise_type, :valid_values => ["on", "off"]
      end

      expect(example_set[:premise_type].index).to eq original_size
    end

    context "keeping/dropping variables" do
      it "re-indexes remaining variables on drop" do
        expect { example_set.drop_vars!(:name) }.to change { example_set[:balance].index }.from(2).to(1)
      end

      it "re-indexes remaining variables on keep" do
        expect { example_set.keep_vars!(:name) }.to change { example_set[:name].index }.from(1).to(0)
      end
    end

    context "reordering variables" do
      before { example_set.order :name, :account_id, :balance }

      it "changes the indexes of reordered variables" do
        expect([:account_id, :name, :balance].collect { |name| example_set[name].index }).to eq [1,0,2]
      end
      
      it "loops through variables in the indexed order" do
        index_order = example_set.collect { |name, var| var.index }
        expect(index_order).to eq 0.upto(example_set.size-1).to_a
      end
    end

    context "combining variablesets" do
      let(:derived_set) do
        VariableSet.new do |v|
          v.var :account_type
          v.var :name,        :comment => "this is overwritten"
          v.like example_set
        end
      end

      it "contains the combination of variables in the right order" do
        expect([:account_type, :name, :account_id, :balance].collect { |name| derived_set[name].index }).to eq [0,1,2,3]
      end

      it 'overwrites metadata with the last one defined' do
        expect(derived_set[:name].meta).not_to include(:comment)
      end
    end
  end
end


