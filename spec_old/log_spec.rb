require 'remi_spec'
require 'stringio'

describe "Remi Logger" do
  before do
    @file = StringIO.new
    RemiLog.systest @file
    RemiLog.systest.level = Logger::ERROR
  end

  after { RemiLog.delete :systest }

  it "should log at the specified level" do
    RemiLog.systest.error "Reporting at Error level"
    expect(@file.string).to include("Error level")
  end

  it "should not log above the specified level" do
    RemiLog.systest.debug "Reporting at Debug level"
    expect(@file.string).not_to include("Debug level")
  end

  it "should respond to changes in the log level" do
    RemiLog.systest.level = Logger::INFO
    RemiLog.systest.info "Reporting at the Info level"
    expect(@file.string).to include("Info level")
  end


  it "should only create the logger object once even when called from another class" do
    outer_object_id = RemiLog.systest.object_id
    class Garbonzo
      def initialize
        RemiLog.systest.error "I am a Garbonzo Error"
        @id = RemiLog.systest.object_id
      end
      attr_accessor :id
    end
    expect(Garbonzo.new.id).to eq outer_object_id
  end
end
