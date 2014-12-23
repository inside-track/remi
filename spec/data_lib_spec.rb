require 'remi_spec'

describe DataLib do
  describe 'forwarding to the canonical data lib' do
    let(:data_lib) { DataLib.new(dir_name: RemiConfig.work_dirname) }

    it 'sets the correct data lib type' do
      expect(data_lib.data_lib_type).to eq 'Remi::DataLibs::CanonicalDataLib'
    end

    it 'delegates calls to the canonical data lib class' do
      expect(data_lib.dir_name).to eq RemiConfig.work_dirname
    end
  end
end
