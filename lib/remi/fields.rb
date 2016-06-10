module Remi
  class Fields < SimpleDelegator
    def initialize(fields=Hash.new({}))
      @fields = Hash.new({}).merge fields
      super(@fields)
    end


    def dup
      Fields.new(@fields.dup)
    end

    def merge(other_fields, prefix: nil)
      dup.merge!(other_fields, prefix: prefix)
    end

    def merge!(other_fields, prefix: nil)
      @fields.merge!(other_fields) do |key, this_val, other_val|
        if prefix
          @fields["#{prefix}#{key}".to_sym] = other_val
          this_val
        else
          this_val.merge other_val
        end
      end
    end

  end
end
