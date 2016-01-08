module Daru
  class DataFrame
    def monkey_dup
      dupdf = Daru::DataFrame.new([], index: self.index)
      self.vectors.each do |v|
        dupdf[v] = self[v]
      end

      dupdf
    end

    def monkey_merge(other)
      other.vectors.each do |v|
        self[v] = other[v]
      end

      self
    end

    def hash_dump(filename)
      File.write(filename, Marshal.dump(self.to_hash))
    end

    def self.from_hash_dump(filename)
      Daru::DataFrame.new(Marshal.load(File.read(filename)))
    end
  end
end
