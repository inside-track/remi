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

  describe Transform::ParseDate do
    it 'parses a date using the specified in_format' do
      parser = Transform::ParseDate.new(in_format: '%m/%d/%Y')
      expect(parser.call('03/22/2011')).to eq Date.new(2011,3,22)
    end

    it 'returns a date if it has already been parsed' do
      parser = Transform::ParseDate.new(in_format: '%m/%d/%Y')
      expect(Date.new(2011,3,22)).to eq Date.new(2011,3,22)
    end

    it 'uses ISO 8601 as the default date parser' do
      parser = Transform::ParseDate.new
      expect(parser.call('2011-03-22')).to eq Date.new(2011,3,22)
    end

    it 'fails when an unparseable date is provided' do
      parser = Transform::ParseDate.new
      expect { parser.call('03/22/2011') }.to raise_error ArgumentError
    end

    it 'parses datetimes when the type is specified' do
      parser = Transform::ParseDate.new(type: :datetime, in_format: '%m/%d/%Y %H:%M:%S')
      expect(parser.call('03/22/2011 04:22:00')).to eq Time.new(2011,3,22,4,22,0)
    end

    it 'uses ISO 8601 as the default datetime parser' do
      parser = Transform::ParseDate.new(type: :datetime)
      expect(parser.call('2011-03-22 04:22:00')).to eq Time.new(2011,3,22,4,22,0)
    end
  end

  context Transform::FormatDate do
    it 'formats a date using the specified out_format' do
      formatter = Transform::FormatDate.new(out_format: '%m/%d/%Y')
      expect(formatter.call(Date.new(2011,3,22))).to eq '03/22/2011'
    end

    it 'formats a datetime using the specified out_format' do
      formatter = Transform::FormatDate.new(type: :datetime, out_format: '%m/%d/%Y %H:%M:%S')
      expect(formatter.call(Time.new(2011,3,22,4,22,0))).to eq '03/22/2011 04:22:00'
    end

    it 'uses the in_format to parse strings when the source is not already a date' do
      formatter = Transform::FormatDate.new(in_format: '%d/%m/%Y', out_format: '%m/%d/%Y')
      expect(formatter.call('22/03/2011')).to eq '03/22/2011'
    end

    it 'fails when an unparseable date is provided' do
      formatter = Transform::FormatDate.new(in_format: '%d/%m/%Y', out_format: '%m/%d/%Y')
      expect { formatter.call('22/22/2011') }.to raise_error ArgumentError
    end

    it 'uses ISO 8601 as the default date parser' do
      formatter = Transform::FormatDate.new(out_format: '%m/%d/%Y')
      expect(formatter.call('2011-03-22')).to eq '03/22/2011'
    end

    it 'uses ISO 8601 as the default date formatter' do
      formatter = Transform::FormatDate.new(in_format: '%m/%d/%Y')
      expect(formatter.call('03/22/2011')).to eq '2011-03-22'
    end

    it 'uses ISO 8601 as the default datetime parser' do
      formatter = Transform::FormatDate.new(type: :datetime, out_format: '%m/%d/%Y %H:%M:%S')
      expect(formatter.call('2011-03-22 04:22:00')).to eq '03/22/2011 04:22:00'
    end

    it 'uses ISO 8601 as the default datetime formatter' do
      formatter = Transform::FormatDate.new(type: :datetime, in_format: '%m/%d/%Y %H:%M:%S')
      expect(formatter.call('03/22/2011 04:22:00')).to eq '2011-03-22 04:22:00'
    end
  end

end
