class CSV
  def self.datastep(filename,options = Hash.new, header_to_vars: nil, &b)
    if header_to_vars
      self.datastep_trust_headers(filename, header_to_vars, options, &b)
    else
      self.datastep_explicit_headers(filename, options, &b)
    end
  end


  def self.datastep_explicit_headers(filename, options, &b)
    # Assume there is always a header, even if we're doing explicit headers
    # If there is no header, then user will have to specify :skip_n_lines => 0
    dsoptions = { :skip_n_lines => 1}
    dsoptions.merge!(options.delete(:dataset)) if options.has_key?(:dataset)

    skip_n_lines = dsoptions[:skip_n_lines]
    open(filename, "r", options) do |rows|
      rows.each do |row|
        yield row if $. > skip_n_lines
      end
    end
  end


  def self.datastep_trust_headers(filename, header_to_vars, options, &b)
    dsoptions = { :skip_n_lines => 0}
    dsoptions.merge!(options.delete(:dataset)) if options.has_key?(:dataset)

    options.merge!({:headers => true, :return_headers => true})

    skip_n_lines = dsoptions[:skip_n_lines]
    open(filename, "r", options) do |rows|

      if rows.header_row?
        rows.readline

        Variables.define header_to_vars do |v|
          rows.headers.each do |header|
            v.create header.to_sym
          end
        end
      end
        
      rows.each do |row|
        puts "ROW: #{row.inspect}"
        yield row if $. > skip_n_lines
      end
    end
  end
end



module Remi
  class Dataset

    def read_row_from_csv(row)
      puts "This is a #{row.class.name}"
      if row.is_a?(Array)
        read_row_from_csv_array(row)
      elsif row.is_a?(CSV::Row)
        read_row_from_csv_hash(row)
      else
        raise TypeError, "Expecting a csv row Array or CSV::Row"
      end
    end

    def read_row_from_csv_array(row)
      @vars.each do |var_name,var_obj|
        next unless var_obj.has_key?(:csv_col)
        self[var_name] = row[var_obj[:csv_col]]
      end
    end


    def read_row_from_csv_hash(row)
      row.each do |key,value|
        self[key.to_sym] = value
      end
    end
  end
end
