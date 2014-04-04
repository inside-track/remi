class CSV
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

    def read_row_from_csv(row)
      if row.is_a?(Array)
        read_row_from_csv_array(row)
      elsif row.is_a?(Hash)
        read_row_from_csv_hash(row)
      else
        raise TypeError, "Expecting a csv row Array or Hash"
      end
    end

    def read_row_from_csv_array(row)
      @vars.each do |var_name,var_obj|
        next unless var_obj.has_key?(:csv_col)
        self[var_name] = row[var_obj[:csv_col]]
      end
    end


    def read_row_from_csv_hash(row)
      @vars.each do |var_name,var_obj|
        if row.has_key?(var_name)
          self[var_name] = row[var_name]
        end
      end
    end

  end
end
