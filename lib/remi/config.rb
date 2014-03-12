module Remi
  # Might want to make configuration a bit more sophisticated and
  # create settings in blocks like this (http://speakmy.name/2011/05/29/simple-configuration-for-ruby-apps/)
  # + create a way to read a json config file

  module RemiConfig
    extend self

    attr_accessor :work_dirname

    @work_dirname = File.join(Dir.home,".remi","tmp")
  end
end
