require_relative '../all_jobs_shared'

class PrefixJob < Remi::Job

  param(:prefix) { 'prefix' }
  source :source_data do
    fields(
      {
        :my_field => {}
      }
    )
  end

  target :target_data

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:my_field) .target(:prefixed_field)
        .transform(Remi::Transform::Prefix.new(job.params[:prefix]))
    end
  end
end
