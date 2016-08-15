module Remi

  # The None extractor doesn't do anything.
  class Extractor::None < Extractor
    def extract
      nil
    end
  end


  # The None Parser just returns what it is given.
  class Parser::None < Parser
    def parse(data)
      data
    end
  end

  # The None Encoder just returns what it is given.
  class Encoder::None < Encoder
    def encode(data_frame)
      data_frame
    end
  end

  # The None loader doesn't do anything.
  class Loader::None < Loader
    def load(data)
      true
    end
  end
end
