require_relative 'all_jobs_shared'

class SharedTransforms < Remi::Job
  sub_transform :id_prefixer, prefix: 'DEFAULT' do
    # Declare the required data subjects and data subject fields
    source :st_source, [:st_source_id]
    target :st_target, [:st_prefixed_id]

    # Do anything that is allowed in a transform with the provided data subjects and fields
    Remi::SourceToTargetMap.apply(st_source.df, st_target.df) do
      map source(:st_source_id) .target(:st_prefixed_id)
        .transform(Remi::Transform::Prefix.new(params[:prefix]))
    end
  end
end

class SubTransformExampleJob < Remi::Job
  param(:job_prefix) { nil }

  source :my_source do
    fields({ :id => {} })
  end

  target :my_target do
    fields(
      {
        :id => {},
        :default_id => {}
      }
    )
  end

  transform :main do
    my_target.df = my_source.df.dup
    sub_trans_params = job.params[:job_prefix].nil? ? {} : { prefix: job.params[:job_prefix] }

    import SharedTransforms.new.id_prefixer, sub_trans_params do
      map_source_fields :my_source, :st_source, { :id => :st_source_id }
      map_target_fields :st_target, :my_target, { :st_prefixed_id => :default_id }
    end

  end
end
