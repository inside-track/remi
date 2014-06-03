require 'remi_spec'

describe "Remi configuration" do
  
  it "should contain the version in the default configuration" do
    expect(RemiConfig.info.version).to eq Remi::VERSION
  end

  it "should prevent the version from being modified" do
    expect { RemiConfig.info.version = "RESET" }.to raise_error(Configatron::LockedError)
  end
  
  it "should allow for simple configuration assignments" do
    RemiConfig.myvar = "Hello"
    expect(RemiConfig.myvar).to eq "Hello"
  end

  it "should allow for nested configuration assignments" do
    RemiConfig.nest.a = "Nest A"
    expect(RemiConfig.nest.a).to eq "Nest A"

    RemiConfig.nest.b = "Nest B"
    expect(RemiConfig.nest.b).to eq "Nest B"

    RemiConfig.nest.deeper.c = "Deeper Nesting C"
    expect(RemiConfig.nest.deeper.c).to eq "Deeper Nesting C"
  end

  it "should only define the user library once", :future => true do
    first_use  = RemiConfig.libs.user.lib
    second_use = RemiConfig.libs.user.lib
    expect(first_use.object_id).to eq second_use.object_id
  end

end
