module Remi
  # Public: Configatron instance used to set global configuration options for Remi
  RemiConfig = Configatron::Store.new

  # Config options in the 'info' namespace cannot be modified
  RemiConfig.info.version = Remi::VERSION
  RemiConfig.info.lock!

  RemiConfig.work_dirname = Dir.mktmpdir("Remi-work", Dir.tmpdir)
  RemiConfig.system_work_dirname = Configatron::Dynamic.new { Dir.mktmpdir("Remi-system_work", Dir.tmpdir) }

  # Number of records to split large datasets for sorting
  RemiConfig.sort.split_size = 1000000
end
