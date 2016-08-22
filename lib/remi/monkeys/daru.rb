# Needed to fix issue in Daru 0.1.4.1
class Daru::DataFrame
  remove_method :to_hash
end
