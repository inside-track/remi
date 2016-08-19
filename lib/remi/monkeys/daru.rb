# These aren't supporting in Daru 0.1.2.  Can be removed after an upgrade.
class Daru::Vector
  def to_df
    Daru::DataFrame.new({@name => @data}, name: @name, index: @index)
  end
end

class Daru::DataFrame
  def to_df
    self
  end
end
