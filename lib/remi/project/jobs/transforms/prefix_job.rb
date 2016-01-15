require_relative '../all_jobs_shared'

class PrefixJob
  include AllJobsShared

  define_param :prefix, 'prefix'
  define_source :source_data, Remi::DataSource::DataFrame
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:field) .target(:field)
        .transform(Remi::Transform[:prefix].(params[:prefix]))
    end
  end
end
