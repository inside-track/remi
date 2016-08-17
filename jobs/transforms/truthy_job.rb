require_relative '../all_jobs_shared'

class TruthyJob < Remi::Job

  source :source_data do
    fields(
      {
        :truthy => {}
      }
    )
  end

  target :target_data

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:truthy) .target(:allow_nils)
        .transform(Remi::Transform::Truthy.new(allow_nils: true))

      map source(:truthy) .target(:no_nils)
        .transform(Remi::Transform::Truthy.new)
    end
  end
end
