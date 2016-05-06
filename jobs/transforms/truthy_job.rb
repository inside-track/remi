require_relative '../all_jobs_shared'

class TruthyJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :truthy => {}
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:truthy) .target(:allow_nils)
        .transform(Remi::Transform::Truthy.new(allow_nils: true))

      map source(:truthy) .target(:no_nils)
        .transform(Remi::Transform::Truthy.new)
    end
  end
end
