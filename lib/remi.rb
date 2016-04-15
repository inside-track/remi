File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(pwd) unless $LOAD_PATH.include?(pwd)}

# Core libraries
require 'yaml'
require 'json'
require 'tmpdir'

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
require 'remi/job'
require 'remi/source_to_target_map'
require 'remi/field_symbolizers'

require 'remi/refinements/symbolizer'

require 'remi/extractor/sftp_file'

require 'remi/fields'
require 'remi/data_frame'
require 'remi/data_frame/daru'

require 'remi/data_subject'
require 'remi/data_subject/csv_file'
#require 'remi/data_subject/salesforce' # intentionally not included by default
require 'remi/data_subject/postgres'
require 'remi/data_subject/sftp_file'
require 'remi/data_subject/data_frame'

require 'remi/transform'
