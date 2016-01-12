module Remi
  module Transformer
    extend self

    def [](meth)
      method(meth)
    end

    # We need to memoize each lambda with its static arguments so it's not recreated each row.
    # Inspired by parameter memoization in http://www.justinweiss.com/articles/4-simple-memoization-patterns-in-ruby-and-one-gem/
    def memoize_as_lambda(func, *args, &block)
      iv = instance_variable_get("@#{func}")
      return iv[args] if iv

      hash_memo = Hash.new do |h, margs|
        h[margs] = lambda { |*largs| block.call(margs, *largs) }
      end
      instance_variable_set("@#{func}", hash_memo)[args]
    end

    def prefixer(prefix)
      memoize_as_lambda(__method__, prefix) do |(mprefix), larg|
        "#{mprefix}#{larg}"
      end
    end

    def postfixer(postfix)
      memoize_as_lambda(__method__, postfix) do |(mpostfix), larg|
        "#{larg}#{mpostfix}"
      end
    end

    def concatenator(delimiter="")
      memoize_as_lambda(__method__, delimiter) do |(mdelimiter), *largs|
        Array(largs).join(mdelimiter)
      end
    end

    def lookup(h_lookup, missing: nil)
      memoize_as_lambda(__method__, h_lookup, missing) do |(mh_lookup, mmissing), larg|
        result = mh_lookup[larg]

        if !result.nil?
          result
        elsif mmissing.class == Proc
          mmissing.call(larg)
        else
          mmissing
        end
      end
    end

    def nvl
      memoize_as_lambda(__method__) do |*largs|
        Array(largs).find('') { |arg| !blank?(arg) }
      end
    end

    def ifblank(replace_with)
      memoize_as_lambda(__method__, replace_with) do |(mreplace_with), larg|
        blank?(larg) ? mreplace_with : larg
      end
    end

    def date_formatter(from_fmt: '%m/%d/%Y', to_fmt: '%Y-%m-%d')
      memoize_as_lambda(__method__, from_fmt, to_fmt) do |(mfrom_fmt, mto_fmt), larg|
        begin
          if blank?(larg) then
            ''
          elsif larg.class == String
            Date.strptime(larg, mfrom_fmt).strftime(mto_fmt)
          else
            larg.strftime(mto_fmt)
          end
        rescue ArgumentError => err
          puts "Error parsing date (#{v.class}): '#{larg}' - #{blank?(larg)}"
          raise err
        end
      end
    end

    def constant(const)
      memoize_as_lambda(__method__, const) do |(mconst), larg|
        mconst
      end
    end

    def replace(regex, replace_with)
      memoize_as_lambda(__method__, regex, replace_with) do |(mregex, mreplace_with), larg|
        larg.gsub(regex, replace_with)
      end
    end

    def email_validator(substitute='')
      memoize_as_lambda(__method__, substitute) do |(msubstitute), larg|
        larg.match(/^.+@[a-z0-9\-\.]+$/i) ? larg : msubstitute
      end
    end

    private

    def blank?(arg)
      arg.nil? || !!arg.strip.empty?
    end

  end
end
