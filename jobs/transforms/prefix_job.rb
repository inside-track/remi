require_relative '../all_jobs_shared'

class PrefixJob
  include AllJobsShared

  define_param :prefix, 'prefix'
  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :my_field => {}
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:my_field) .target(:prefixed_field)
        .transform(Remi::Transform::Prefix.new(params[:prefix]))
    end
  end
end
