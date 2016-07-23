module Remi

  # Defines properties of an entry in a filesystem.
  class Extractor::FileSystemEntry
    # @param pathname [String] The path the file system entry
    # @param create_time [Time] The time the entry was created
    # @param modified_time [Time] The time the entry was last modified
    # @param raw [Object] An object that captures all other aspects of the entry, native to system the entry lives on
    def initialize(pathname:, create_time:, modified_time:, raw: nil)
      @pathname = Pathname.new(pathname)
      @create_time = create_time
      @modified_time = modified_time
      @raw = raw
    end

    attr_reader :pathname, :create_time, :modified_time, :raw

    # @return [String] the base name of the entry
    def name
      @pathname.basename.to_s
    end
  end


  # Parent class used to describe things that behave like file systems (e.g.,
  # local file systems, ftp servers, S3 objects) to be used for extraction.
  #
  # @param remote_path [String] Path on the remote system that contains the files
  # @param pattern [Regexp] Only files with a name that matches this regular
  #  expression are extracted
  # @param local_path [String] Local path to put copies of extracted files
  # @param most_recent_only [true,false] Only extract the most recent file
  #  that matches the given pattern
  # @param group_by [Regexp] A regular expression used to group files together
  #  and only extract the most recent file in each group
  # @param most_recent_by [Symbol] Indicates the FileSystemEntry property used to determine which
  #   file is the most recent(`:create_time` (default), `:modified_time`, `:name`)

  class Extractor::FileSystem < Extractor
    class FileNotFoundError < StandardError; end

    def initialize(*args, **kargs, &block)
      super
      init_file_system(*args, **kargs)
    end

    attr_reader :remote_path
    attr_reader :pattern
    attr_reader :local_path
    attr_reader :most_recent_only
    attr_reader :group_by
    attr_reader :most_recent_by

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

    private

    def init_file_system(*args, remote_path:, pattern: /.*/, local_path: Settings.work_dir, most_recent_only: false, group_by: nil, most_recent_by: :create_time, **kargs, &block)
      @remote_path = Pathname.new(remote_path)
      @pattern = pattern
      @local_path = Pathname.new(local_path)
      @most_recent_only = most_recent_only
      @group_by = group_by
      @most_recent_by = most_recent_by
    end
  end
end
