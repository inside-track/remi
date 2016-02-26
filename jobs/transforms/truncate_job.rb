require_relative '../all_jobs_shared'

class TruncateJob
  include AllJobsShared

  define_param :truncate_len, 5
  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :my_field => {}
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:my_field) .target(:truncated_field)
        .transform(Remi::Transform[:truncate].(params[:truncate_len].to_i))
    end
  end
end
