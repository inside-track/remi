# MOVE THIS TO CORE ADDITIONS
class String
  # Strip leading whitespace from each line that is the same as the 
  # amount of whitespace on the first line of the string.
  # Leaves _additional_ indentation on later lines intact.
  def unindent
    gsub /^#{self[/\A\s*/]}/, ''
  end
end

module Remi

  # Helpers are miscellanous methods that don't belong anywhere else

  # Stolen from http://devblog.avdi.org/2009/07/14/recursively-symbolize-keys/
  # Not sure I really like it.  Might want to convert to a hash method
  def symbolize_keys(hash)
    hash.inject({}){|result, (key, value)|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
      result
    }
  end


  # Random strings for generating dummy/test data (no performance guarantees)
  def rand_alpha(n=10)
    (0..n).map { ('A'..'Z').to_a[rand(26)]}.join
  end


end
