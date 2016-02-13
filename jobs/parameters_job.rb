require_relative 'all_jobs_shared'

class ParametersJob
  include AllJobsShared

  define_param :test_parameter, "my test parameter value"

  define_target :source_data, Remi::DataSource::DataFrame,
    fields: {
      :parameter_name => {}
    }
  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(nil) .target(:myparam)
        .transform(Remi::Transform[:constant].(params[:myparam]))
      map source(:parameter_name) .target(:parameter_name)
        .transform(->(v) { params[v.to_sym] })
    end
  end

end
