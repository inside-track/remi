require_relative 'all_jobs_shared'

class JsonJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :json_array => { type: :json },
      :json_hash  => { type: :json }
    }

  define_target :target_data, Remi::DataTarget::DataFrame,
    fields: {
      :second_element => {},
      :name_field     => {}
    }

  define_transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df, source_metadata: source_data.fields) do
      map source(:json_array) .target(:second_element)
        .transform(->(values) { values[1] })
      map source(:json_hash) .target(:name_field)
        .transform(->(json_hash) { json_hash['name'] })
    end
  end
end
