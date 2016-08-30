require_relative 'all_jobs_shared'

class SftpFileTargetJob < Remi::Job
  target :some_file do
    encoder Remi::Encoder::CsvFile.new
    loader Remi::Loader::SftpFile.new(
      credentials: {
        host: 'example.com',
        username: 'user',
        password: 'secret'
      },
      local_path: "#{Remi::Settings.work_dir}/some_file.csv",
      remote_path: "some_file_#{DateTime.current.strftime('%Y%m%d')}.csv"
    )
  end

  transform :main do
  end
end
