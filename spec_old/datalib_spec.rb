require 'remi_spec'

describe Datalib do
  describe 'forwarding to the canonical datalib' do
    let(:datalib) { Datalib.new(dir_name: RemiConfig.work_dirname) }
    
    it 'sets the correct data lib type' do
      expect(datalib.datalib_type).to eq 'Remi::Datalibs::CanonicalDatalib'
    end

    it 'delegates calls to the canonical data lib class' do
      expect(datalib.dir_name).to eq RemiConfig.work_dirname
    end
  end
end
