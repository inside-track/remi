require 'remi_spec'

describe Variable do

  describe "A variable is an object that has a value and metadata" do

    context "which can be created in one line" do
      let(:testvar) { Variable.new :some_meta => "That's so meta" }

      specify { expect(testvar).to have_key(:some_meta) }

      it "defines the mandatory type key" do
        expect(testvar).to have_key(:type)
      end

      it "can use an array accessor to return metadata" do
        expect(testvar[:some_meta]).to eq "That's so meta"
      end

      it "can modify metadata using an array accesor" do
        testvar[:some_meta] = "Metamodify"
        expect(testvar[:some_meta]).to eq "Metamodify"
      end
    end

    context "and can be defined in a block" do
      let(:testvar) do
        Variable.new do
          meta :type      => "string"
          meta :length    => 18
          meta :some_meta => "More meta than you"
        end
      end

      specify { expect(testvar).to have_key(:length) }

      context "which is useful for importing variable metadata from other variables" do
        let(:testvar_derived) do
          testvar_origin = testvar # Don't understand why testvar not in scope of block below

          Variable.new do
            like testvar_origin
            meta :alt_meta => "Way, way meta"
          end
        end

        specify { expect(testvar_derived).to have_key(:some_meta) }
        specify { expect(testvar_derived).to have_key(:alt_meta) }
      end
    end
  end

  describe "Modifying metadata" do
    subject(:testvar) do
      Variable.new do
        meta :type      => "string"
        meta :length    => 18
        meta :meta_keep => "More meta than you"
        meta :meta_drop => "Way more meta than you"
      end
    end

    shared_examples "surviving metadata" do
      specify { expect(subject).to have_keys(:type, :length, :meta_keep) }
      specify { expect(subject).not_to have_key(:meta_drop) }
    end


    context "can be non-destructively dropped" do
      subject(:testvar_derived) { testvar.drop_meta :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively dropped" do
      before { testvar.drop_meta! :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be non-destructively kept" do
      subject(:testvar_derived) { testvar.keep_meta :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively kept" do
      before { testvar.keep_meta! :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end

    context "can be modified in a block" do
      before do
        testvar.modify! do
          meta :length => 21
        end
      end

      specify { expect(testvar[:length]).to eq 21 }

      context "with drop method specified without a bang" do
        before do
          testvar.modify! do
            drop_meta :meta_drop
          end
        end

        it_behaves_like "surviving metadata"
      end

      context "with keep method specified without a bang" do
        before do
          testvar.modify! do
            keep_meta :length, :meta_keep
          end
        end

        it_behaves_like "surviving metadata"
      end
    end
  end
end
