module Remi::BusinessRules
  using Remi::Core::Refinements

  def self.parse_full_field(full_field_name)
    full_field_name.split(':').map(&:strip)
  end

  def self.csv_opt_map
    {
      'tab'             => "\t",
      'comma'           => ',',
      'pipe'            => '|',
      'double quote'    => '"',
      'single quote'    => "'",
      'windows'         => "\r\n",
      'unix'            => "\n",
      'windows or unix' => :auto,
    }
  end

  class Tester

    def initialize(job_name)
      job_class_name = "#{job_name.gsub(/\s/,'')}Job"
      @job = Object.const_get(job_class_name).new

      @job_sources = DataSubjectCollection.new
      @job_targets = DataSubjectCollection.new

      @sources = DataSubjectCollection.new
      @targets = DataSubjectCollection.new
      @examples = DataExampleCollection.new

      @filestore = Filestore.new
    end

    attr_reader :job
    attr_reader :job_sources
    attr_reader :job_targets
    attr_reader :sources
    attr_reader :targets
    attr_reader :examples
    attr_reader :filestore

    def add_job_source(name)
      raise "Unknown source #{name} for job" unless @job.methods.include? name.symbolize
      @job_sources.add_subject(name, @job.send(name.symbolize))
    end

    def add_job_target(name)
      raise "Unknown target #{name} for job" unless @job.methods.include? name.symbolize
      @job_targets.add_subject(name, @job.send(name.symbolize))
    end


    def add_source(name)
      @sources.add_subject(name, @job.send(name.symbolize))
    end

    def source
      @sources.only
    end

    def add_target(name)
      @targets.add_subject(name, @job.send(name.symbolize))
    end

    def target
      @targets.only
    end


    def add_example(example_name, example_table)
      @examples.add_example(example_name, example_table)
    end

    def run_transforms
      @job.run_all_transforms
    end
  end




  class DataSubjectCollection
    include Enumerable

    def initialize
      @subjects = {}
    end

    def [](subject_name)
      @subjects[subject_name]
    end

    def each(&block)
      @subjects.each &block
    end

    def keys
      @subjects.keys
    end

    def add_subject(subject_name, subject)
      @subjects[subject_name] ||= DataSubject.new(subject)
    end

    def add_field(full_field_name)
      if full_field_name.include? ':'
        subject_name, field_name = *Remi::BusinessRules.parse_full_field(full_field_name)
        @subjects[subject_name].add_field(field_name)
      else
        @subjects.each do |subject_name, subject|
          subject.add_field(full_field_name)
        end
      end
    end

    def only
      raise "Multiple subjects defined: #{keys}" unless @subjects.size == 1
      @subjects.values.first
    end

    def fields
      dfc = DataFieldCollection.new
      @subjects.each do |subject_name, subject|
        subject.fields.each { |field_name, field| dfc.add_field(subject, field_name) }
      end
      dfc
    end

    def size
      @subjects.size
    end

    def total_size
      @subjects.reduce(0) { |sum, (name, subject)| sum += subject.size }
    end
  end


  class DataSubject
    def initialize(subject)
      @data_obj = subject
      @fields = DataFieldCollection.new

      stub_data
    end

    attr_reader :data_obj

    def add_field(field_name)
      @fields.add_field(self, field_name)
    end

    def field
      @fields.only
    end

    def fields
      @fields
    end

    def size
      @data_obj.df.size
    end

    # For debugging only
    def _df
      @data_obj.df
    end



    def stub_data
      @data_obj.stub_df if @data_obj.respond_to? :stub_df
    end

    def stub_data_with(example)
      stub_data
      @data_obj.df = example.to_df(@data_obj.df.row[0].to_hash, field_symbolizer: @data_obj.field_symbolizer)
    end


    def replicate_rows(n_rows)
      replicated_df = Daru::DataFrame.new([], order: @data_obj.df.vectors.to_a)
      @data_obj.df.each do |vector|
        replicated_df[vector.name] = vector.to_a * n_rows
      end
      @data_obj.df = replicated_df
    end

    def cumulative_dist_from_freq_table(table, freq_field: 'frequency')
      cumulative_dist = {}
      freq_total = 0
      table.hashes.each do |row|
        low = freq_total
        high = freq_total + row[freq_field].to_f
        freq_total = high
        cumulative_dist[(low...high)] =   row.tap { |r| r.delete(freq_field) }
      end
      cumulative_dist
    end

    def generate_values_from_cumulative_dist(n_records, cumulative_dist)
      # Use the same key for reproducible tests
      psuedorand = Random.new(3856382695386)

      1.upto(n_records).reduce({}) do |h, idx|
        r = psuedorand.rand
        row_as_hash = cumulative_dist.select { |range| range.include? r }.values.first
        row_as_hash.each do |field_name, value|
          h[field_name] ||= []
          h[field_name] << value
        end
        h
      end
    end

    def distribute_values(table)
      cumulative_dist = cumulative_dist_from_freq_table(table)
      generated_data = generate_values_from_cumulative_dist(@data_obj.df.size, cumulative_dist)

      generated_data.each do |field_name, data_array|
        vector_name = fields[field_name].name
        @data_obj.df[vector_name] = Daru::Vector.new(data_array, index: @data_obj.df.index)
      end
    end

    def freq_by(*field_names)
      @data_obj.df.group_by(field_names).size * 1.0 / @data_obj.df.size
    end

    def mock_extractor(filestore)
      extractor = class << @data_obj.extractor; self; end

      extractor.send(:define_method, :all_entries, ->() { filestore.sftp_entries })
      extractor.send(:define_method, :download, ->(to_download) { to_download.map { |e| e.name } })
    end

    def extract
      @data_obj.extractor.extract
    end

    def csv_options
      @data_obj.csv_options
    end

  end


  class DataFieldCollection
    include Enumerable

    def initialize
      @fields = {}
    end

    def [](field_name)
      @fields[field_name]
    end

    def each(&block)
      @fields.each(&block)
    end

    def keys
      @fields.keys
    end

    def names
      @fields.values.map(&:name)
    end

    def add_field(subject, field_name)
      @fields[field_name] = DataField.new(subject.data_obj, field_name) unless @fields.include? field_name
    end

    def only
      raise "Multiple subject fields defined: #{keys}" if @fields.size > 1
      @fields.values.first
    end

    def values
      @fields.map { |field_name, field| field.values }.transpose
    end
  end


  class DataField
    def initialize(subject, field_name)
      @subject = subject
      @field_name = field_name.symbolize(subject.field_symbolizer)
    end

    def name
      @field_name
    end

    def metadata
      @subject.fields[name]
    end

    def vector
      @subject.df[@field_name]
    end

    def value
      v = vector.to_a.uniq
      raise "Multiple unique values found in subject data for field #{@field_name}" if v.size > 1
      v.first
    end

    def values
      vector.to_a
    end

    def value=(arg)
      vector.recode! { |v| arg }
    end
  end


  class DataExampleCollection
    include Enumerable

    def initialize
      @examples = {}
    end

    def [](example_name)
      @examples[example_name]
    end

    def each(&block)
      @examples.each(&block)
    end

    def keys
      @examples.keys
    end

    def add_example(example_name, example_table)
      @examples[example_name] = DataExample.new(example_table) unless @examples.include? example_name
    end
  end


  class DataExample
    def initialize(table)
      @table = table
    end

    def to_df(seed_hash, field_symbolizer:)
      df = Daru::DataFrame.new([], order: seed_hash.keys)
      @table.hashes.each do |example_row|
        example_row_sym = example_row.reduce({}) { |h, (k,v)| h[k.symbolize(field_symbolizer)] = v; h }
        df.add_row(seed_hash.merge(example_row_sym))
      end
      df
    end
  end


  class Filestore
    def initialize
      @files = []
      @delivered = {}
    end

    attr_reader :sftp_entries

    def pattern(pattern)
      @pattern = pattern
    end

    def anti_pattern(pattern)
      @pattern = /^ThisBetterNeverMatchAnythingOrIWillShootYou\d{8}Times$/
    end

    def delivered_since(date_time)
      @delivered = { :since => date_time }
    end

    def delivered_before(date_time)
      @delivered = { :before => date_time }
    end

    def latest
      @files.max_by { |f| f[:attributes][:createdtime] }[:name]
    end

    def generate
      psuedorand = Random.new(4985674985672348954987589429)

      generate_files_with_pattern
      @files.map! do |file|
        date_method = @delivered.keys.first
        if date_method == :since
          file[:attributes][:createdtime] = @delivered[:since] + 10 + psuedorand.rand * 100
        elsif date_method == :before
          file[:attributes][:createdtime] = @delivered[:since] - 10 - psuedorand.rand * 100
        else
          file[:attributes][:createdtime] = Time.now - 10 - psuedorand.rand * 100
        end
        file
      end
    end

    def sftp_entries
      @files.map do |file|
        Net::SFTP::Protocol::V04::Name.new(
          file[:name],
          Net::SFTP::Protocol::V04::Attributes.new(createtime: file[:attributes][:createdtime])
        )
      end
    end

    private

    def generate_files_with_pattern
      filenames = 1.upto(5).map { |f| @pattern.random_example }.uniq

      @files = filenames.map do |fname|
        {
          name: fname,
          attributes: {
            createdtime: nil
          }
        }
      end
    end
  end
end
