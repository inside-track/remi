module Remi

  # Local file extractor
  # Used to "extract" a file from a local filesystem.
  # Note that even though the file is local, we still use the parameter `remote_path`
  # to indicate the path.  This makes this class consistent with Remi::FileSystem.
  #
  # @example
  #
  #  class MyJob < Remi::Job
  #    source :some_file do
  #      extractor Remi::Extractor::LocalFile.new(
  #        remote_path: 'some_file.csv'
  #      )
  #      parser Remi::Parser::CsvFile.new(
  #        csv_options: {
  #          headers: true,
  #          col_sep: '|'
  #        }
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.some_file.df
  #  # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #  #                    id       name
  #  #          0          1     Albert
  #  #          1          2      Betsy
  #  #          2          3       Camu
  class Extractor::LocalFile < Extractor::FileSystem
    def initialize(*args, **kargs)
      super
      init_local_file(*args, **kargs)
    end

    # Called to extract files from the source filesystem.
    # @return [Array<String>] An array of paths to a local copy of the files extacted
    def extract
      entries.map(&:pathname)
    end

    # @return [Array<Extractor::FileSystemEntry>] List of objects in the remote path
    def all_entries
      @all_entries ||= all_entries!
    end

    # @return [Array<Extractor::FileSystemEntry>] List of objects in the remote path
    def all_entries!
      dir = @remote_path.directory? ? @remote_path + '*' : @remote_path
      Dir[dir].map do |entry|
        path = Pathname.new(entry)
        if path.file?
          Extractor::FileSystemEntry.new(
            pathname: path.realpath.to_s,
            create_time: path.ctime,
            modified_time: path.mtime
          )
        end
      end.compact
    end

    private

    def init_local_file(*args, **kargs)
    end
  end


  # Local file loader
  # Used to output files to a local filesystem
  # @example
  #  class MyJob < Remi::Job
  #    target :my_target do
  #      encoder Remi::Encoder::CsvFile.new(
  #        csv_options: { col_sep: '|' }
  #      )
  #      loader Remi::Loader::LocalFile.new(
  #        path: 'test.csv'
  #      )
  #    end
  #  end
  #
  #  my_df = Daru::DataFrame.new({ a: 1.upto(5).to_a, b: 6.upto(10) })
  #  job = MyJob.new
  #  job.my_target.df = my_df
  #  job.my_target.load
  class Loader::LocalFile < Loader
    def initialize(*args, **kargs)
      super
      init_local_file_loader(*args, **kargs)
    end

    # Moves the file from the temporary workspace to another local path
    # @param data [Object] The path to the file in the temporary work location
    # @return [true] On success
    def load(data)
      logger.info "Writing file #{@local_path}"
      FileUtils.mv(data, @local_path)
    end


    private

    def init_local_file_loader(*args, path:, **kargs)
      @local_path = path
    end
  end
end
