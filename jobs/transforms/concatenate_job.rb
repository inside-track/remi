require_relative '../all_jobs_shared'

class ConcatenateJob
  include AllJobsShared

  define_param :delimiter, ','
  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :field1 => {},
      :field2 => {},
      :field3 => {}
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:field1, :field2, :field3) .target(:result_field)
        .transform(Remi::Transform::Concatenate.new(params[:delimiter]))
    end
  end
end
