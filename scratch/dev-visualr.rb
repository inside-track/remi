# Load the Remi library
load "#{File.dirname(__FILE__)}/../lib/remi.rb"

Log.level Logger::DEBUG

v = Dataview.new
v.create_table
v.table_tpl
v.view_table


