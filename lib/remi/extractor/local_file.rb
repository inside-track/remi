module Remi
  module Extractor

    class LocalFile < FileSystem
      def initialize(*args, **kargs)
        super
        init_local_file(*args, **kargs)
      end

      # Public: Called to extract files from the source filesystem.
      #
      # Returns an array with containing the paths to all files extracted.
      def extract
        entries.map(&:pathname)
      end

      # Public: Returns an array of all FileSystemEntry instances that are in the remote_path.
      def all_entries
        @all_entries ||= all_entries!
      end

      def all_entries!
        dir = @remote_path.directory? ? @remote_path + '*' : @remote_path
        Dir[dir].map do |entry|
          path = Pathname.new(entry)
          if path.file?
            FileSystemEntry.new(
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
  end
end
