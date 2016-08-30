require_relative '../all_jobs_shared'

class DateDiffJob < Remi::Job

  param(:measure) { :days }

  source :source_data do
    fields(
      {
        :date1 => { type: :date, format: '%Y-%m-%d' },
        :date2 => { type: :date, format: '%Y-%m-%d' }
      }
    )
  end

  target :target_data

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:date1, :date2) .target(:difference)
        .transform(->(row) {
          row[:date1] = Date.strptime(row[:date1])
          row[:date2] = Date.strptime(row[:date2])
        })
        .transform(Remi::Transform::DateDiff.new(job.params[:measure]))
    end
  end
end
