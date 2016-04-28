require_relative '../all_jobs_shared'

class DateDiffJob
  include AllJobsShared

  define_param :measure, :days
  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :date1 => { type: :date, format: '%Y-%m-%d' },
      :date2 => { type: :date, format: '%Y-%m-%d' }
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:date1, :date2) .target(:difference)
        .transform(->(d1,d2) { [Date.strptime(d1), Date.strptime(d2)] })
        .transform(Remi::Transform::DateDiff.new(params[:measure]))
    end
  end
end
