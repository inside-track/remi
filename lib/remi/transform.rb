module Remi
  module Transform
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

    def prefix(prefix, if_blank: '')
      memoize_as_lambda(__method__, prefix, if_blank) do |(mprefix, mif_blank), larg|
        if larg.blank?
          mif_blank
        else
          "#{mprefix}#{larg}"
        end
      end
    end

    def postfix(postfix, if_blank: '')
      memoize_as_lambda(__method__, postfix, if_blank) do |(mpostfix, mif_blank), larg|
        if larg.blank?
          mif_blank
        else
          "#{larg}#{mpostfix}"
        end
      end
    end

    def truncate(len)
      memoize_as_lambda(__method__, len) do |(mlen), larg|
        larg.slice(0,mlen)
      end
    end

    def concatenate(delimiter="")
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

    def nvl(default='')
      memoize_as_lambda(__method__, default) do |(mdefault), *largs|
        Array(largs).find(->() { mdefault }) { |arg| !arg.blank? }
      end
    end

    def ifblank(replace_with)
      memoize_as_lambda(__method__, replace_with) do |(mreplace_with), larg|
        larg.blank? ? mreplace_with : larg
      end
    end

    def format_date(from_fmt: '%m/%d/%Y', to_fmt: '%Y-%m-%d')
      memoize_as_lambda(__method__, from_fmt, to_fmt) do |(mfrom_fmt, mto_fmt), larg|
        begin
          if larg.blank? then
            ''
          elsif larg.respond_to? :strftime
            larg.strftime(mto_fmt)
          else
            Date.strptime(larg, mfrom_fmt).strftime(mto_fmt)
          end
        rescue ArgumentError => err
          puts "Error parsing date (#{larg.class}): '#{larg}'"
          raise err
        end
      end
    end


    def parse_date(format: '%Y-%m-%d', if_blank: nil)
      memoize_as_lambda(__method__, format, if_blank.try(:to_sym)) do |(mformat, mif_blank), larg|
        begin
          if larg.respond_to?(:strftime)
            larg
          elsif larg.blank? then
            if mif_blank == :low
              Date.new(1900,01,01)
            elsif mif_blank == :high
              Date.new(2999,12,31)
            else
              mif_blank
            end
          else
            Date.strptime(larg, mformat)
          end
        rescue ArgumentError => err
          puts "Error parsing date (#{larg.class}): '#{larg}')"
          raise err
        end
      end
    end

    def date_diff(measure = :days)
      memoize_as_lambda(__method__, measure.to_sym) do |(mmeasure), *larg|
        if mmeasure == :days
          (larg.last - larg.first).to_i
        elsif mmeasure == :months
          (larg.last.year * 12 + larg.last.month) - (larg.first.year * 12 + larg.first.month)
        elsif mmeasure == :years
          larg.last.year - larg.first.year
        else
          raise "I don't know how to handle #{mmeasure} yet"
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

    def validate_email(substitute='')
      memoize_as_lambda(__method__, substitute) do |(msubstitute), larg|
        larg = larg || ''
        larg.match(/^[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,}$/i) ? larg : msubstitute
      end
    end

  end
end
