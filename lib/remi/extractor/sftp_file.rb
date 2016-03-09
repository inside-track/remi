module Remi
  module Extractor

    class LocalFile
      def initialize(path:, folder: nil)
        @path = path
        @folder = folder
      end

      def extract
        if @folder
          Dir.entries(@folder).map do |entry|
            next unless entry.match(@path)
            File.join(@folder,entry)
          end.compact
        else
          @path
        end
      end
    end

    class SftpFile

      class FileNotFoundError < StandardError; end

      SortDesc = Struct.new(:value) do
        def <=> (target)
          -(self.value <=> target.value)
        end
      end

      def initialize(credentials:, remote_file:, remote_folder: '', local_folder: Settings.work_dir, port: nil, most_recent_only: false, group_by: nil, most_recent_by: :createtime, logger: Remi::Settings.logger)
        @credentials = credentials
        @remote_file = remote_file
        @remote_folder = remote_folder
        @local_folder = local_folder
        @port = port || (credentials && credentials[:port]) || '22'
        @most_recent_only = most_recent_only
        @group_by = group_by
        @most_recent_by = most_recent_by
        @logger = logger
      end

      attr_reader :logger

      def extract
        raise FileNotFoundError, "File not found: #{@remote_file}" if to_download.size == 0
        download(to_download)
      end

      def to_download
        if @group_by
          most_recent_in_group
        elsif @most_recent_only
          Array(most_recent_entry(matching_entries))
        else
          matching_entries
        end
      end

      def all_entries(remote_folder = @remote_folder)
        @all_entries ||= connection { |sftp| sftp.dir.entries(File.join("/", remote_folder)) }
      end

      def matching_entries(match_name = @remote_file)
        all_entries.select { |e| match_name.match e.name }
      end

      def most_recent_entry(entries = matching_entries)
        entries.sort_by { |e| sort_files_by(e) }.reverse!.first
      end

      def sort_files_by(entry)
        if @most_recent_by == :filename
          entry.name
        else
          entry.attributes.send(@most_recent_by)
        end
      end

      def most_recent_in_group(match_group = @group_by)
        entries_with_group = matching_entries.map do |entry|
          match = entry.name.match(match_group)
          next unless match

          group = match.to_a[1..-1]
          { group: group, entry: entry }
        end.compact
        entries_with_group.sort_by! { |e| [e[:group], SortDesc.new(sort_files_by(e[:entry]))] }

        last_group = nil
        entries_with_group.map do |entry|
          next unless entry[:group] != last_group
          last_group = entry[:group]
          entry[:entry]
        end.compact
      end

      def download(entries_to_download, remote_folder: @remote_folder, local_folder: @local_folder, ntry: 3)
        connection do |sftp|
          entries_to_download.map do |entry|
            local_file = File.join(local_folder, entry.name)
            @logger.info "Downloading #{entry.name} to #{local_file}"
            retry_download(ntry) { sftp.download!(File.join(remote_folder, entry.name), local_file) }
            local_file
          end
        end
      end


      private

      def connection(&block)
        result = nil
        Net::SFTP.start(@credentials[:host], @credentials[:username], password: @credentials[:password], port: @port) do |sftp|
          result = yield sftp
        end
        result
      end

      def retry_download(ntry=2, &block)
        1.upto(ntry).each do |itry|
          begin
            block.call
            break
          rescue RuntimeError => err
            raise err unless itry < ntry
            @logger.error "Download failed with error: #{err.message}"
            @logger.error "Retry attempt #{itry}/#{ntry-1}"
            sleep(1)
          end
        end
      end
    end
  end
end
