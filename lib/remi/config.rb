module Remi
  # Public: Configatron instance used to set global configuration options for Remi
  RemiConfig = Configatron::Store.new

  # Config options in the 'info' namespace cannot be modified
  RemiConfig.info.version = Remi::VERSION
  RemiConfig.info.lock!

  RemiConfig.work_dirname = Dir.mktmpdir("Remi-work-", Dir.tmpdir)
  RemiConfig.system_work_dirname = Configatron::Dynamic.new { Dir.mktmpdir("Remi-system_work-", Dir.tmpdir) }

  # Default logging output
  RemiConfig.log.output = STDOUT

  # Default log level
  RemiConfig.log.level = Logger::ERROR

  # Define two standard loggers:
  #   RemiLog.sys is for general Remi logging
  #   RemiLog.row is for very detailed logging that may print multiple logging messages per row.
  RemiConfig.log.sys = Configatron::Dynamic.new { RemiLog.sys }
  RemiConfig.log.row = Configatron::Dynamic.new { RemiLog.row }

  # Number of records to split large data sets for sorting
  RemiConfig.sort.split_size = 1000000
end
