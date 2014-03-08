task :default => [:test_all]

task :test_Datalib do
  ruby "test/remi/Datalib/test_datalib.rb"
end

task :test_Dataset do
  ruby "test/remi/Dataset/test_write_and_read.rb"
end

task :test_all => [:test_Datalib, :test_Dataset] do
end

task :test_all do
  ruby "test/unittest.rb"
end

task :bye do
  ruby "test/unittest2.rb"
end




