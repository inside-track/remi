require 'remi_spec'

describe DataLibs::ShellDataLib do

  let(:mylib) { DataLib.new(:shell) }

  it 'does something', skip: 'FLESH THIS OUT' do
    puts mylib.inspect
    ds = mylib.build(:mydata)
    ds.define_variables do
      var :monster
      var :cakes
    end
    puts ds.to_yaml
  end

end
