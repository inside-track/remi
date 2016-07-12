require_relative '../remi_spec'
require 'remi/testing/data_stub'

describe Testing::DataStub do
  class StubTester < DataSubject
    include Testing::DataStub
  end

  context 'data type stubs' do
    let(:stub_tester) { StubTester.new }

    context '#stub_string' do
      let(:stub) { stub_tester.stub_string }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end
    end

    context '#stub_float' do
      let(:stub) { stub_tester.stub_float }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end

      it 'represents a floating point number' do
        expect(Float(stub) % 1).not_to eq 0.0
      end
    end

    context '#stub_decimal' do
      let(:stub) { stub_tester.stub_decimal(precision: 8, scale: 2) }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end

      it 'represents a floating point number' do
        expect(Float(stub) % 1).not_to eq 0.0
      end

      it 'comes with the specified precision' do
        expect(Float(stub).to_s.split('.').first.size).to eq 8
      end

      it 'comes with the specified scale' do
        expect(Float(stub).to_s.split('.').last.size).to eq 2
      end
    end

    context '#stub_integer' do
      let(:stub) { stub_tester.stub_integer }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end

      it 'represents an integer' do
        expect(Float(stub) % 1).to eq 0.0
      end

      it 'converts to an integer' do
        expect { Integer(stub) }.not_to raise_error
      end
    end


    context '#stub_date' do
      context 'without an in_format' do
        let(:stub) { stub_tester.stub_date }

        it 'stubs as a date' do
          expect(stub).to be_a Date
        end
      end

      context 'with an in_format' do
        let(:stub) { stub_tester.stub_date(in_format: '%m/%d/%Y') }

        it 'stubs as strings' do
          expect(stub).to be_a String
        end

        it 'can parsed as a date using the specified in_format' do
          expect { Date.strptime(stub, '%m/%d/%Y') }.not_to raise_error
        end
      end
    end

    context '#stub_datetime' do
      context 'without an in_format' do
        let(:stub) { stub_tester.stub_datetime }

        it 'stubs as a time' do
          expect(stub).to be_a Time
        end
      end

      context 'with an in_format' do
        let(:stub) { stub_tester.stub_datetime(in_format: '%m/%d/%Y %H:%M:%S') }

        it 'stubs as strings' do
          expect(stub).to be_a String
        end

        it 'can parsed as a time using the specified in_format' do
          expect { Time.strptime(stub, '%m/%d/%Y %H:%M:%S') }.not_to raise_error
        end
      end
    end

    context '#stub_boolean' do
      let(:stub) { stub_tester.stub_boolean }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end

      it 'is either T or F' do
        expect(stub).to eq('T').or eq('F')
      end
    end

    context '#stub_json' do
      let(:stub) { stub_tester.stub_json }

      it 'stubs as strings' do
        expect(stub).to be_a String
      end

      it 'can be parsed as JSON' do
        expect { JSON.parse(stub) }.not_to raise_error
      end
    end
  end


  context 'stubbed dataframe data' do
    let(:stub_tester) do
      StubTester.new(fields: {
        my_date: { type: :date, in_format: '%m/%d/%Y' },
        my_str: {}
      })
    end

    context '#empty_stub_df' do
      before { stub_tester.empty_stub_df }

      it 'creates a dataframe with no data' do
        expect(stub_tester.df.size).to eq 0
      end

      it 'creates a dataframe with the right number of vectors' do
        expect(stub_tester.df.vectors.size).to eq 2
      end
    end

    context '#stub_df' do
      before { stub_tester.stub_df }

      it 'creates a row of data' do
        expect(stub_tester.df.size).to eq 1
      end

      it 'creates data according to the supplied metadata' do
        expect { Date.strptime(stub_tester.df[:my_date].first, '%m/%d/%Y') }.not_to raise_error
      end
    end
  end
end
