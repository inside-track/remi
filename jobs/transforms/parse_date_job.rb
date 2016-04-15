require_relative '../all_jobs_shared'

class ParseDateJob
  include AllJobsShared

  define_param :format, '%Y-%m-%d'
  define_param :if_blank, nil
  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :date_string  => { type: :date, in_format: params[:format] },
      :stubbed_date => { type: :date, in_format: params[:format] }
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do

    # Only needed for testing, would be nice to make it testable without this
    params[:if_blank] = ['high', 'low'].include?(params[:if_blank]) ? params[:if_blank].to_sym : params[:if_blank]

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:date_string) .target(:parsed_date)
        .transform(Remi::Transform::ParseDate.new(in_format: params[:format], if_blank: params[:if_blank]))

      map source(:stubbed_date) .target(:parsed_stubbed_date)
        .transform(Remi::Transform::ParseDate.new(in_format: params[:format], if_blank: params[:if_blank]))
    end
  end
end
