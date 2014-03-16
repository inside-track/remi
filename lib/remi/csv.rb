# REFACTOR: Put this class in an "interface" directory
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
