require_relative '../all_jobs_shared'

class TruncateJob < Remi::Job

  param(:truncate_len) { 5 }

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
      map source(:my_field) .target(:truncated_field)
        .transform(Remi::Transform::Truncate.new(job.params[:truncate_len].to_i))
    end
  end
end
