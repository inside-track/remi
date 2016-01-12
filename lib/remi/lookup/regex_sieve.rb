module Remi
  module Lookup
    class RegexSieve
      def initialize(sieve)
        @sieve = sieve
      end

      def [](key)
        value = @sieve.find do |regex, v|
          regex.match(key)
        end

        value.nil? ? nil : value[1]
      end
    end
  end
end
