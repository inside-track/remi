require_relative '../all_jobs_shared'

class NvlJob < Remi::Job

  param(:default) { '' }

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
        .transform(Remi::Transform::Nvl.new(job.params[:default]))
    end
  end
end
