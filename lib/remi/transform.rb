module Remi
  class Transform

    # Public: Initializes the static arguments of a transform.
    #
    # source_metadata - Metadata for the transform source.
    # target_metadata - Metadata for the transform target.
    def initialize(*args, source_metadata: {}, target_metadata: {}, **kargs, &block)
      @source_metadata = source_metadata
      @target_metadata = target_metadata
      @multi_args = false
    end

    # Public: Accessor for source metadata
    attr_accessor :source_metadata

    # Public: Accessor for target metadata
    attr_accessor :target_metadata

    # Public: Set to true if the transform expects multiple arguments (default: false)
    attr_reader :multi_arg

    # Public: Defines the operation of this transform class.
    #
    # value - The value to be transformed
    #
    # Returns the transformed value.
    def transform(value)
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

    # Public: Allows one to call the proc defined by the transform so that
    # Remi::Transform instances can be used interchangeably with normal lambdas.
    #
    # values - The values to be transformed.
    #
    # Returns the transformed value.
    def call(*values)
      if @multi_arg
        to_proc.call(*values)
      else
        to_proc.call(Array(values).first)
      end
    end

    # Public: Returns the transform as a lambda.
    def to_proc
      @to_proc ||= method(:transform).to_proc
    end






    # Public: Transform used to prefix string values in a vector.
    #
    # prefix   - The string prefix.
    # if_blank - String value to substitute if the value is blank (default: '').
    #
    # Examples:
    #
    #  Prefix.new('CU').to_proc.call('123') # => "CU123"
    class Prefix < Transform
      def initialize(prefix, *args, if_blank: '', **kargs, &block)
        super
        @prefix   = prefix
        @if_blank = if_blank
      end

      def transform(value)
        if value.blank?
          @if_blank
        else
          "#{@prefix}#{value}"
        end
      end
    end


    # Public: Transform used to postfix values in a vector.
    #
    # postfix  - The string postfix.
    # if_blank - String value to substitute if the value is blank (default: '').
    #
    # Examples:
    #
    #  Postfix.new('A').to_proc.call('123') # => "123A"
    class Postfix < Transform
      def initialize(postfix, *args, if_blank: '', **kargs, &block)
        super
        @postfix   = postfix
        @if_blank = if_blank
      end

      def transform(value)
        if value.blank?
          @if_blank
        else
          "#{value}#{@postfix}"
        end
      end
    end


    # Public: Transform used to truncate values in a vector.
    #
    # len - The maximum length of the string.
    #
    # Examples:
    #
    #  Truncate.new(3).to_proc.call('1234') # => "123"
    class Truncate < Transform
      def initialize(len, *args, **kargs, &block)
        super
        @len = len
      end

      def transform(value)
        (value || '').slice(0,@len)
      end
    end

    # Public: Transform used to concatenate a list of values, joined by a delimiter.
    #
    # delimiter - The delimiter used between values in the list (default: '').
    #
    # Examples:
    #
    #  Concatenate.new('-').to_proc.call('a', 'b', 'c') # => "a-b-c"
    class Concatenate < Transform
      def initialize(delimiter='', *args, **kargs, &block)
        super
        @multi_args = true
        @delimiter = delimiter
      end

      def transform(*values)
        Array(values).join(@delimiter)
      end
    end


    # Public: Transform used to do key-value lookup on hash-like objects
    #
    # lookup  - The lookup object that takes keys and returns values.
    # missing - What to use if a key is not found in the lookup (default: nil).  If this
    #           is a proc, it is sent the key as an argument.
    #
    # Examples:
    #
    #  my_lookup = { 1 => 'one', 2 => 'two }
    #  Lookup.new().to_proc.call(1) # => "1"
    #  Lookup.new().to_proc.call(3) # => nil
    #  Lookup.new().to_proc.call(3, missing: 'UNK') # => "UNK"
    #  Lookup.new().to_proc.call(3, missing: ->(v) { "I don't know #{v}" }) # => "I don't know 3"
    class Lookup < Transform
      def initialize(lookup, *args, missing: nil, **kargs, &block)
        super
        @lookup  = lookup
        @missing = missing
      end

      def transform(value)
        result = @lookup[value]

        if !result.nil?
          result
        elsif @missing.respond_to? :call
          @missing.call(value)
        else
          @missing
        end
      end
    end

    # Public: (Next-Value-Lookup) transform used to find the first non-blank value in a list.
    #
    # default - What to use if all values are blank (default: '').
    #
    # Examples:
    #
    #  Nvl.new.to_proc.call(nil,'','a','b') # => "a"
    class Nvl < Transform
      def initialize(default='', *args, **kargs, &block)
        super
        @multi_args = true
        @default = default
      end

      def transform(*values)
        Array(values).find(->() { @default }) { |arg| !arg.blank? }
      end
    end

    # Public: Used to replace blank values.
    #
    # replace_with - Use this if the source value is blank (default: '').
    #
    # Examples:
    #
    #  IfBlank.new('MISSING VALUE').to_proc.call('alpha') # => "alpha"
    #  IfBlank.new('MISSING VALUE').to_proc.call('') # => "MISSING VALUE"
    class IfBlank < Transform
      def initialize(replace_with='', *args, **kargs, &block)
        super
        @replace_with = replace_with
      end

      def transform(value)
        value.blank? ? @replace_with : value
      end
    end

    # Public: Parses a string and converts it to a date.
    # This transform is metadata aware and will use :in_format metadata
    # from the source
    #
    # in_format - The date format to use to convert the string (default: uses :in_format
    #             from the source metadata.  If that is not defined, use '%Y-%m-%d').
    # if_blank  - Value to use if the the incoming value is blank (default: uses :if_blank
    #             from the source metadata.  If that is not defined, use nil).  If set to
    #             :high, then use the largest date, if set to :ow, use the lowest date.
    #
    # Examples:
    #
    #  ParseDate.new(in_format: '%m/%d/%Y').to_proc.call('02/22/2013') # => Date.new(2013,2,22)
    #
    #  tform = ParseDate.new
    #  tform.source_metadata = { in_format: '%m/%d/%Y' }
    #  tform.to_proc.call('02/22/2013') # => Date.new(2013,2,22)
    class ParseDate < Transform
      def initialize(*args, in_format: nil, if_blank: nil, **kargs, &block)
        super
        @in_format = in_format
        @if_blank  = if_blank
      end

      def in_format
        @in_format ||= @source_metadata.fetch(:in_format, '%Y-%m-%d')
      end

      def if_blank
        @if_blank ||= @source_metadata.fetch(:if_blank, nil)
      end

      def transform(value)
        begin
          if value.respond_to?(:strftime)
            value
          elsif value.blank? then
            blank_handler(value)
          else
            string_to_date(value)
          end
        rescue ArgumentError => err
          raise err, "Error parsing date (#{value.class}): '#{value}' with format #{in_format})"
        end
      end

      def string_to_date(value)
        Date.strptime(value, in_format)
      end

      def blank_handler(value)
        if if_blank == :low
          Date.new(1900,01,01)
        elsif if_blank == :high
          Date.new(2999,12,31)
        elsif if_blank.respond_to? :call
          if_blank.call(value)
        else
          if_blank
        end
      end
    end


    # Public: (Re)formats a date.
    # This transform is metadata aware and will use :in_format/:out_format metadata
    # from the source.
    #
    # in_format  - The date format to used to parse the input value.  If the input value
    #              is a date, then then parameter is ignored.  (default: uses :in_format
    #              from the source metadata.  If that is not defined, use '%Y-%m-%d')
    # out_format - The date format applied to provide the resulting string.  (default:
    #              uses :out_format from the source metadata.  If that is not defined,
    #              use '%Y-%m-%d')
    #
    # Examples:
    #
    #  FormatDate.new(in_format: '%m/%d/%Y', out_format: '%Y-%m-%d').to_proc.call('02/22/2013') # => "2013-02-22"
    #
    #  tform = FormatDate.new
    #  tform.source_metadata = { in_format: '%m/%d/%Y', out_format: '%Y-%m-%d' }
    #  tform.to_proc.call('02/22/2013') # => "2013-02-22"
    class FormatDate < Transform
      def initialize(*args, in_format: nil, out_format: nil, **kargs, &block)
        super
        @in_format  = in_format
        @out_format = out_format
      end

      def in_format
        @in_format ||= @source_metadata.fetch(:in_format, '%Y-%m-%d')
      end

      def out_format
        @out_format ||= @source_metadata.fetch(:out_format, '%Y-%m-%d')
      end

      def transform(value)
        begin
          if value.blank? then
            ''
          elsif value.respond_to? :strftime
            value.strftime(out_format)
          else
            Date.strptime(value, in_format).strftime(out_format)
          end
        rescue ArgumentError => err
          raise err, "Error parsing date (#{value.class}): '#{value}' using the format #{in_format} => #{out_format}"
        end
      end
    end

    # Public: Used to calculate differences between dates by a given measure.
    #
    # measure - One of :days, :months, or :years. (default: :days).
    #
    # Examples:
    #
    #  DateDiff.new(:months).to_proc.call([Date.new(2016,1,30), Date.new(2016,3,1)]) # => 2
    class DateDiff < Transform
      def initialize(measure = :days, *args, **kargs, &block)
        super
        @multi_args = true
        @measure = measure
      end

      def transform(from_date, to_date)

        case @measure.to_sym
        when :days
          (to_date - from_date).to_i
        when :months
          (to_date.year * 12 + to_date.month) - (from_date.year * 12 + from_date.month)
        when :years
          to_date.year - from_date.year
        else
          raise ArgumentError, "Unknown date difference measure: #{@measure}"
        end
      end
    end

    # Public: Simply returns a constant.
    #
    # constant - The constant value to return.
    #
    # Examples:
    #
    #  Constant.new('ewoks').to_proc.call('whatever') # => 'ewoks'
    class Constant < Transform
      def initialize(constant, *args, **kargs, &block)
        super
        @constant = constant
      end

      def transform(values)
        @constant
      end
    end

    # Public: Replaces one substring with another.
    #
    # to_replace   - The string or regex to be replaced.
    # repalce_with - The value to substitute.
    #
    # Examples:
    #
    #  Replace.new(/\s/, '-').to_proc.call('hey jude') #=> 'hey-jude'
    class Replace < Transform
      def initialize(to_replace, replace_with, *args, **kargs, &block)
        super
        @to_replace   = to_replace
        @replace_with = replace_with
      end

      def transform(value)
        (value || '').gsub(@to_replace, @replace_with)
      end
    end

    # Public: Checks to see if an email validates against a regex (imperfect)
    # and will substitute it with some value if not.
    #
    # substitute - The value used to substitute for an invalid email.  Can use a proc
    #              that accepts the value of the invalid email
    #
    # Examples:
    #
    #  ValidateEmail.new('invalid@example.com').to_proc.call('uhave.email') #=> 'invalid@example.com'
    #  ValidateEmail.new(->(v) { "#{SecureRandom.uuid}@example.com" }).to_proc.call('uhave.email') #=> '3f158f29-bc75-44f0-91ed-22fbe5157297@example.com'
    class ValidateEmail < Transform
      def initialize(substitute='', *args, **kargs, &block)
        super
        @substitute   = substitute
      end

      def transform(value)
        value = value || ''
        if value.match(/^[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,}$/i)
          value
        elsif @substitute.respond_to? :call
          @substitute.call value
        else
          @substitute
        end
      end
    end



    # Public: Enforces the type declared in the :type metadata field (if it exists)
    #
    # Examples:
    #
    #  tform = EnforceType.new
    #  tform.source_metadata = { type: :date, in_format: '%m/%d/%Y' }
    #  tform.to_proc.call('02/22/2013') # => Date.new(2013,2,22)
    #
    #  tform = EnforceType.new
    #  tform.source_metadata = { type: :integer }
    #  tform.to_proc.call('12') # => 12
    #
    #  tform = EnforceType.new
    #  tform.source_metadata = { type: :integer }
    #  tform.to_proc.call('12A') # => ArgumentError: invalid value for Integer(): "12A"
    class EnforceType < Transform
      def initialize(*args, **kargs, &block)
        super
      end

      def type
        @type ||= @source_metadata.fetch(:type, :string)
      end

      def in_format
        @in_format ||= @source_metadata.fetch(:in_format, '')
      end

      def scale
        @scale ||= @source_metadata.fetch(:scale, 0)
      end

      def if_blank
        return @if_blank if @if_blank_set
        @if_blank_set = true
        @if_blank = @source_metadata.fetch(:if_blank, nil)
      end

      def blank_handler(value)
        return value unless value.blank?

        if if_blank.respond_to? :to_proc
          if_blank.to_proc.call(value)
        else
          if_blank
        end
      end

      def transform(value)
        if value.blank?
          blank_handler(value)
        else
          case type
          when :string
            value
          when :integer
            Integer(value)
          when :float
            Float(value)
          when :decimal
            Float("%.#{scale}f" % Float(value))
          when :date
            value.is_a?(Date) ? value : Date.strptime(value, in_format) # value.is_a?(Date) is only needed becuase we stub date types with actual dates, rather than strings like we probably should
          when :datetime
            Time.strptime(value, in_format)
          else
            raise ArgumentError, "Unknown type enforcement: #{type}"
          end
        end
      end
    end





    # Public: Converts strings into booleans.
    # Uses a regex to convert strings representing booleans to actual booleans.
    # The truthy regex is /^(t|true|y|yes|1)$/i and the falsey regex is /^(f|false|n|no|0)$/i
    #
    # allow_nils - Specifies whether to allow the result to include nils.  If this is set
    #              to false, then the value is only checked against the truthy regex and
    #              the returned value is false if it doesn't match.  If allow_nils
    #              is set to true, the both the truthy and the falsey regex are checked.
    #              If neither match, then the result is nil.  (Default: false).
    #
    # Examples:
    #
    # Truthy.new.to_proc.call('True')                         # => true
    # Truthy.new.to_proc.call('Yes')                          # => true
    # Truthy.new.to_proc.call('y')                            # => true
    # Truthy.new.to_proc.call('Yessire')                      # => false
    # Truthy.new.to_proc.call('0')                            # => false
    # Truthy.new.to_proc.call('Pineapple')                    # => false
    # Truthy.new(allow_nils: false).to_proc.call('Pineapple') # => nil
    class Truthy < Transform
      def initialize(*args, allow_nils: false, **kargs, &block)
        super
        @allow_nils = allow_nils

        @true_regex = /^(t|true|y|yes|1)$/i
        @false_regex = /^(f|false|n|no|0)$/i
      end

      def match_true(value)
        !!value.match(@true_regex)
      end

      def match_false(value)
        !!value.match(@false_regex)
      end

      def transform(value)
        value = value.to_s

        if @allow_nils
          if match_true(value)
            true
          elsif match_false(value)
            false
          else
            nil
          end
        else
          match_true(value)
        end
      end
    end


    # Public: Applies a DataFrame grouping sieve.
    #
    # The DataFrame sieve can be used to simplify very complex nested
    # if-then logic to group data into buckets.  Given a DataFrame
    # with N columns, the first N-1 columns represent the variables
    # needed to group data into buckets.  The last column is the
    # desired group.  The sieve then progresses down the rows of the
    # DataFrame and checks to see if the input data matches the values
    # in the columns of the sieve.  Nils in the sieve are treated as
    # wildcards and match anything.  The first row that matches wins
    # and the sieve progression stops.
    #
    # sieve_df - The sieve, defined as a dataframe.  The arguments
    #            to the transform must appear in the same order as the
    #            first N-1 columns of the sieve.
    #
    #
    # Examples:
    #
    #   # This sieve captures the following business logic
    #   # 1 - All Non-Graduate Nursing, regardless of contact, gets assigned to the :intensive group.
    #   # 2 - All Undergraduate programs with contact get assigned to the :intensive group.
    #   # 3 - All Undergraduate programs without a contact get assigned to the :base group.
    #   # 4 - All Graduate engineering programs with a contact get assigned to the :intensive group.
    #   # 5 - All other programs get assigned to the :base group
    #   sieve_df = Daru::DataFrame.new([
    #     [ 'Undergrad' , 'NURS' , nil   , :intensive ],
    #     [ 'Undergrad' , nil    , true  , :intensive ],
    #     [ 'Undergrad' , nil    , false , :base ],
    #     [ 'Grad'      , 'ENG'  , true  , :intensive ],
    #     [ nil         , nil    , nil   , :base ],
    #     ].transpose,
    #     order: [:level, :program, :contact, :group]
    #     )
    #
    #   test_df = Daru::DataFrame.new([
    #     ['Undergrad' , 'CHEM' , false],
    #     ['Undergrad' , 'CHEM' , true],
    #     ['Grad'      , 'CHEM' , true],
    #     ['Undergrad' , 'NURS' , false],
    #     ['Unknown'   , 'CHEM' , true],
    #     ].transpose,
    #     order: [:level, :program, :contact]
    #   )
    #
    #   Remi::SourceToTargetMap.apply(test_df) do
    #     map source(:level, :program, :contact,) .target(:group)
    #     .transform(Remi::Transform::DataFrameSieve.new(sieve_df))
    #   end
    #
    #   test_df
    #   # =>  #<Daru::DataFrame:70099624408400 @name = d30888fd-6ca8-48dd-9be3-558f81ae1015 @size = 5>
    #             level    program    contact      group
    #      0  Undergrad       CHEM        nil       base
    #      1  Undergrad       CHEM       true  intensive
    #      2       Grad       CHEM       true       base
    #      3  Undergrad       NURS        nil  intensive
    #      4    Unknown       CHEM       true       base
    class DataFrameSieve < Transform
      def initialize(sieve_df, *args, **kargs, &block)
        super
        @sieve_df = sieve_df.transpose.to_h.values
      end

      def transform(*values)
        sieve_keys = @sieve_df.first.index.to_a
        sieve_result_key = sieve_keys.pop

        @sieve_df.each.find do |sieve_row|
          match_row = true
          sieve_keys.each_with_index do |key,idx|
            match_row &&= sieve_row[key].nil? || sieve_row[key] == values[idx]
          end
          match_row
        end[sieve_result_key]
      end
    end


    # Public: Used to partition elements into groups (buckets).
    #
    # buckets            - A hash where the keys are groups and the values are weights or percentages.
    # current_population - A hashable object holding a count of the current number of
    #                      elements in each bucket.
    #
    # Example:
    #
    #   # The current population has 2 record in the A bucket and 3 in B
    #   current_pop = Daru::Vector.new([2,3], index: ['A', 'B'])
    #
    #   # We want to generate 7 new records that will evenly populate the A, B, and C buckets, given the current populations.
    #   part = Remi::Transform::Partitioner.new(buckets: { 'A' => 1, 'B' => 1,'C' => 1 }, initial_population: current_pop)
    #
    #   1.upt(7).map { |iter| part.call } # => ["C", "C", "A", "C", "C", "B", "A"]
    class Partitioner < Transform
      def initialize(buckets:, initial_population: {}, **kargs, &block)
        super
        @buckets = buckets
        @current_population = sanitize_initial_population(buckets, initial_population)
      end

      attr_reader :buckets
      attr_reader :current_population

      def transform(*values)
        get_next_value
      end

      def size
        @size ||= @current_population.reduce(0) { |sum, (group, n)| sum += n }
      end

      def total_weight
        @total_weight ||= @buckets.reduce(0) { |sum, (bucket, weight)| sum += 1.0 * weight }
      end

      def get_next_value
        assigned = @buckets.max_by do |(group, weight)|
          expected = @buckets[group] / total_weight * size
          actual = @current_population[group]

          diff = expected - actual
          if diff > 0
            rand**(1.0 / diff)
          else
            -rand**(- 1.0 / @buckets[group])
          end
        end.first

        @current_population[assigned] += 1
        @size += 1

        assigned
      end

      private

      def sanitize_initial_population(buckets, dist)
        dist = dist.to_h

        zero_distribution = buckets.keys.reduce({}) { |h, group| h[group] = 0; h }
        zero_distribution.merge(dist.select { |k,v| buckets.keys.include? k })
      end
    end


  end
end
