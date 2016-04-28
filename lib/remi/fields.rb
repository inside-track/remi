module Remi
  class Fields < SimpleDelegator
    def initialize(fields=Hash.new({}))
      @fields = Hash.new({}).merge fields
      super(@fields)
    end
  end
end
