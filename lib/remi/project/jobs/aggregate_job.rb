require_relative 'all_jobs_shared'

class AggregateJob
  include AllJobsShared
  using Remi::Refinements::Daru

  define_source :source_data, Remi::DataSource::DataFrame
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do

    mymin = lambda do |field, df, indicies|
      values = indicies.map { |idx| df.row[idx][field] }
      values.min
    end

    target_data.df = source_data.df.aggregate(by: :alpha, func: mymin.curry.(:year)).detach_index
    target_data.df.vectors = Daru::Index.new([:alpha, :year])
  end
end
