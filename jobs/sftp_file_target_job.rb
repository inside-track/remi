require_relative 'all_jobs_shared'

class SftpFileTargetJob
  include AllJobsShared


  define_target :some_file, Remi::DataTarget::SftpFile,
    credentials: {
      host: 'example.com',
      username: 'user',
      password: 'secret'
    },
    local_path: "#{Remi::Settings.work_dir}/some_file.csv",
    remote_path: "some_file_#{DateTime.current.strftime('%Y%m%d')}.csv"

  define_transform :main do
  end
end
