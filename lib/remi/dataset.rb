module Remi
  class Dataset

    def initialize
      @variables = {}
      @row = {} # I do want row to be an array, but use a has for the moment
         # or maybe not, maybe I just want the data output to file to be array, internally it can be a hash
    end

    def add_variable(varname,varmeta)

      tmpvarlist = @variables.merge({ varname => varmeta })

      if not tmpvarlist[varname].has_key?(:type)
        raise ":type not defined for variable #{varname}"
      end

      @variables = tmpvarlist
      @row[varname] = nil

    end

    def []=(varname,value)
      if @row.has_key?(varname)
        @row[varname] = value
      else
        raise "Variable '#{varname}' not defined"
      end
    end

    def [](varname)
      @row[varname]
    end

    def output

      printf "|"
      @row.each do |key,value|
        printf "#{key}=#{value}|"
      end
      printf "\n"

  #    puts "#{@row.inspect}"
    end

  end
end
