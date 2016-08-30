require_relative '../all_jobs_shared'

class ParseDateJob < Remi::Job

  param(:format) { '%Y-%m-%d' }
  param(:if_blank) { nil }

  source :source_data do
    fields(
      {
        :date_string  => { type: :date, in_format: params[:format] },
        :stubbed_date => { type: :date, in_format: params[:format] }
      }
    )
  end

  target :target_data

  transform :main do
    # Only needed for testing, would be nice to make it testable without this
    job.params[:if_blank] = ['high', 'low'].include?(job.params[:if_blank]) ? job.params[:if_blank].to_sym : job.params[:if_blank]

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:date_string) .target(:parsed_date)
        .transform(Remi::Transform::ParseDate.new(in_format: job.params[:format], if_blank: job.params[:if_blank]))

      map source(:stubbed_date) .target(:parsed_stubbed_date)
        .transform(Remi::Transform::ParseDate.new(in_format: source_data.fields[:stubbed_date][:in_format], if_blank: job.params[:if_blank]))
    end
  end
end
