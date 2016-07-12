require 'rspec/expectations'
require 'cucumber/rspec/doubles'

require 'regexp-examples'

require_relative 'testing/data_stub'
require_relative 'testing/business_rules'

class Remi::DataSource
  include Remi::Testing::DataStub
end
