require 'remi_spec'

describe VariableSet do

  # Pre-define some dummy shared variables to be used in variable sets
  let(:shared_vars) do
    {
      :account_id => (Variable.new :length => 18),
      :name       => (Variable.new :length => 80),
    }
  end

  describe "A variable set is a collection of variables" do

    context "can be created in one line" do
      subject(:varset) { VariableSet.new :account_id => shared_vars[:account_id], :name => shared_vars[:name] }

      it { should have_keys(:account_id, :name) }

      context "using an array accessor to return a variable" do
        specify { expect(subject[:name]).to eq shared_vars[:name] }
      end
    end

    context "can be defined in a block" do
      let(:varset) do
        VariableSet.new do
          var :account_id => shared_vars[:account_id]
          var :name       => shared_vars[:name]
          var :balance    => { :type => "currency" }
        end
      end
    end

  end
end
