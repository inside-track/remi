require_relative 'all_jobs_shared'

class CopySourceJob
  include AllJobsShared
  using Remi::Refinements::Daru

  define_source :source_data, Remi::DataSource::DataFrame
  define_source :target_data, Remi::DataSource::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    target_data.df = source_data.df.dup
  end
end
