require_relative 'remi_spec'

describe Transform do

  context 'a transform with a single argument' do
    before do
      class SingleArgument < Transform
        def initialize(*args, **kargs, &block)
          super
        end

        def transform(value)
          value
        end
      end
    end

    let(:transform) { SingleArgument.new }

    it 'can be converted into a proc and called' do
      expect(transform.to_proc.call(5)).to eq 5
    end

    it 'can be called directly' do
      expect(transform.call(5)).to eq 5
    end
  end

  context 'a transform that accepts multiple arguments' do
    before do
      class MultipleArgument < Transform
        def initialize(*args, **kargs, &block)
          super
          @multi_args = true
        end

        def transform(*values)
          Array(values)
        end
      end
    end

    let(:transform) { MultipleArgument.new }

    it 'can be converted into a proc and called' do
      expect(transform.to_proc.call(1, 2)).to eq [1, 2]
    end

    it 'can be called directly' do
      expect(transform.call(1, 2)).to eq [1, 2]
    end
  end
end
