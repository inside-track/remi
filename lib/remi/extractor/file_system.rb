module Remi
  module Extractor

    class FileSystemEntry
      def initialize(pathname:, create_time:, modified_time:, raw: nil)
        @pathname = Pathname.new(pathname)
        @create_time = create_time
        @modified_time = modified_time
        @raw = raw
      end

      attr_reader :pathname, :create_time, :modified_time, :raw

      def name
        @pathname.basename.to_s
      end
    end


    class FileSystem

      class FileNotFoundError < StandardError; end

      def initialize(*args, remote_path:, pattern: /.*/, local_path: Settings.work_dir, most_recent_only: false, group_by: nil, most_recent_by: :create_time, logger: Remi::Settings.logger, **kargs, &block)
        @remote_path = Pathname.new(remote_path)
        @pattern = pattern
        @local_path = Pathname.new(local_path)
        @most_recent_only = most_recent_only
        @group_by = group_by
        @most_recent_by = most_recent_by
        @logger = logger
      end

      attr_reader :logger

      # Public: Called to extract files from the source filesystem.
      #
      # Returns an array with containing the paths to all files extracted.
      def extract
        raise NoMethodError, "#{__method__} not defined for#{self.class.name}"
      end

      # Public: Returns an array of all FileSystemEntry instances that are in the remote_path.
      # NOTE: all_entries is responsible for matching the path using @remote_path
      def all_entries
        raise NoMethodError, "#{__method__} not defined for#{self.class.name}"
      end

      # Public: Returns just the entries that are to be extracted.
      def entries
        if @group_by
          most_recent_matching_entry_in_group
        elsif @most_recent_only
          Array(most_recent_matching_entry)
        else
          matching_entries
        end
      end

      def matching_entries
        all_entries.select { |e| @pattern.match e.name }
      end

      def most_recent_matching_entry
        matching_entries.sort_by { |e| e.send(@most_recent_by) }.reverse.first
      end

      def most_recent_matching_entry_in_group
        entries_with_group = matching_entries.map do |entry|
          match = entry.name.match(@group_by)
          next unless match

          group = match.to_a[1..-1]
          { group: group, entry: entry }
        end.compact
        sorted_entries_with_group = entries_with_group.sort_by { |e| [e[:group], e[:entry].send(@most_recent_by)] }.reverse

        last_group = nil
        sorted_entries_with_group.map do |entry|
          next unless entry[:group] != last_group
          last_group = entry[:group]
          entry[:entry]
        end.compact
      end
    end
  end
end
