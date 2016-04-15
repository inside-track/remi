require_relative 'all_jobs_shared'

class CopySourceJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :some_field => {},
      :some_date => { type: :date, format: '%Y-%m-%d' }
    }
  define_source :target_data, Remi::DataSource::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    target_data.df = source_data.df.dup
  end
end
