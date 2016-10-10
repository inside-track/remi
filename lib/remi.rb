File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(pwd) unless $LOAD_PATH.include?(pwd)}

# Core libraries
require 'yaml'
require 'json'
require 'tmpdir'
require 'fileutils'
 

# Gems
require 'daru'
require 'docile'
require 'net/sftp'
require 'pg'
require 'regex_sieve'
require 'faker'

# ActiveSupport extensions
require 'active_support'
require 'active_support/core_ext/object/conversions'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/string/filters'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/numeric/conversions'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/time/calculations'

# - Should separate SF stuff into separate SF support package
#require 'restforce'
#require 'salesforce_bulk_api'


# Remi
require 'remi/version.rb'

require 'remi/settings'
require 'remi/dsl'
require 'remi/job'
require 'remi/job/parameters'
require 'remi/job/sub_job'
require 'remi/job/transform'
require 'remi/source_to_target_map'
require 'remi/source_to_target_map/map'
require 'remi/source_to_target_map/row'
require 'remi/field_symbolizers'

require 'remi/refinements/symbolizer'

require 'remi/extractor'
require 'remi/parser'
require 'remi/encoder'
require 'remi/loader'

require 'remi/data_subject'
require 'remi/data_subjects/file_system'
require 'remi/data_subjects/local_file'
require 'remi/data_subjects/gsheet_file'
require 'remi/data_subjects/sftp_file'
require 'remi/data_subjects/s3_file'
require 'remi/data_subjects/csv_file'
#require 'remi/data_subjects/salesforce' # intentionally not included by default
require 'remi/data_subjects/postgres'
require 'remi/data_subjects/data_frame'
require 'remi/data_subjects/none'
require 'remi/data_subjects/sub_job'

require 'remi/fields'
require 'remi/data_frame'
require 'remi/data_frame/daru'

require 'remi/transform'

require 'remi/monkeys/daru'

# Remi is Ruby Extract Modify and Integrate, a framework for writing ETL job in Ruby.
module Remi
end
