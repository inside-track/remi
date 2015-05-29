require 'remi_spec'

describe Interfaces::BasicInterface do

  let(:mylib) { DataLibs::BasicDataLib.new }
  let(:interface) { Interfaces::BasicInterface.new(mylib, 'test') }


  describe 'expected methods' do
    subject { interface }
    it { respond_to? :eof_flag }
    it { respond_to? :eof_flag= }
    it { respond_to? :open_for_write }
    it { respond_to? :open_for_read }
    it { respond_to? :read_metadata }
    it { respond_to? :write_metadata }
    it { respond_to? :read_row }
    it { respond_to? :write_row }
    it { respond_to? :close }
    it { respond_to? :data_set_exists? }
    it { respond_to? :create_empty_data_set }
    it { respond_to? :data_set }
  end

  describe 'reading a row' do
    it 'gives back an empty row' do
      interface.set_key_map VariableSet.new(:a, :b)
      expect(interface.read_row).to be_a(Row)
    end
  end

end
