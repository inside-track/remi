module Remi
  module Lookup

    # Public: RegexSieve class.  The RegexSieve functions in a manner similar
    # a hash.  The regex sieve is initialized with a hash where the keys are
    # regular expressions and the values can be any valid Ruby object.  The order
    # of the keys matters.  When the regex sieve is accessed using the array
    # accessor [], it returns the first matching record.  By default, only
    # the values are returned, but the key and all matching capture groups
    # can optionally be returned.
    #
    # Examples:
    #
    #   r = RegexSieve.new({
    #     /something/ => 'Something',
    #     /something else/ => 'This will never get matched because the one above will match first',
    #     /cool$/ => 'Cool',
    #     /cool beans/ => 'Really Cool'
    #   })
    #
    #   r['something else'] # => 'Something'
    #   r['cool beans'] # => 'Really Cool'
    class RegexSieve
      def initialize(sieve)
        @sieve = sieve
      end

      # Public: Array accessor for Regex Sieve.
      #
      # key - The string that will be matched to the keys in the sieve.
      # opt - By default, only the values in the hash used to initialize the sieve
      #       will be returned.  However, if you want to return the keys or the
      #       capture groups then use :regex, :match, or both, respectively.
      #
      # Example:
      #   r['something'] # => 'Something
      #   r['something', :regex] # => { value: 'Something', regex: /something/ }
      #   r['sometinng', :match, :regex] # => { value: 'Something', regex: /something/, match: #<MatchData "something"> }
      def [](key, *opt)
        opt = opt | [:value]

        regex_match = nil
        found = @sieve.find do |regex, v|
          regex_match = regex.match(key)
        end

        return nil if found.nil?
        full_result = { value: found[1], regex: found[0], match: regex_match }

        full_result.select! { |k, v| opt.include?(k) }
        full_result.size > 1 ? full_result : full_result.values.first
      end
    end
  end
end
