require_relative '../all_jobs_shared'

class ConcatenateJob < Remi::Job

  param(:delimiter) { ',' }

  source :source_data do
    fields(
      {
        :field1 => {},
        :field2 => {},
        :field3 => {}
      }
    )
  end

  target :target_data

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:field1, :field2, :field3) .target(:result_field)
        .transform(Remi::Transform::Concatenate.new(job.params[:delimiter]))
    end
  end
end
