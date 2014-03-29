=begin
class CSV

  # Default is to always skip a header row

  def self.datastep(filename,mode,options = Hash.new,&b)

    # Assume there is always a header, even if we're doing explicit headers
    dsoptions = { :skip_n_lines => 1}
    dsoptions.merge!(options.delete(:dataset)) if options.has_key?(:dataset)

    skip_n_lines = dsoptions[:skip_n_lines]
    open(filename,mode,options) do |rows|
      rows.each do |row|
        yield row if $. > skip_n_lines
      end
    end
  end

end



module Remi
  class Dataset

    def set_values_from_csv(row)
      if row.is_a?(Array)
        set_values_from_csv_array(row)
      elsif row.is_a?(Hash)
        set_values_from_csv_hash(row)
      else
        raise TypeError, "Expecting a csv row Array or Hash"
      end
    end

    # REFACTOR: can I change these if statement to enumerable select?
    # Starting to think that I need to rethink my variable structure
    # @variables vs Variable is confusing
    def set_values_from_csv_array(row)
      @vars.select do |var_name,var_obj|
        var_obj.meta.has_key?(:csv_col)
      end
    end


f=begin
      @vars.each do |var_name,var_obj|
        if var_obj.meta.has_key?(:csv_col)
          col = var_obj.meta[:csv_col]
          @vars[var_name] = row[col]
        end
      end
f=end
    end

    def set_values_from_csv_hash(row)
      @vars.each do |var_name,var_obj|
        if row.has_key(var_name)
          @vars[var_name] = row[var_name]
        end
      end
    end

  end
end
=end
