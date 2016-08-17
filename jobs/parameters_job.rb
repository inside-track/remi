require_relative 'all_jobs_shared'

class ParametersJob < Remi::Job
  param(:myparam) {}
  param(:test_parameter) { "my test parameter value" }

  source :source_data do
    fields(
      {
        :parameter_name => {}
      }
    )
  end

  target :target_data

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map target(:myparam)
        .transform(Remi::Transform::Constant.new(job.params[:myparam]))
      map source(:parameter_name) .target(:parameter_name)
        .transform(->(v) { job.params[v.to_sym] })
    end
  end

end
