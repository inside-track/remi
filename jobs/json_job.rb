require_relative 'all_jobs_shared'

class JsonJob < Remi::Job
  source :source_data do
    fields(
      {
        :json_array => { type: :json },
        :json_hash  => { type: :json }
      }
    )
  end

  target :target_data do
    fields(
      {
        :second_element => {},
        :name_field     => {}
      }
    )
  end

  transform :main do
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df, source_metadata: source_data.fields) do
      map source(:json_array) .target(:second_element)
        .transform(->(values) { values[1] })
      map source(:json_hash) .target(:name_field)
        .transform(->(json_hash) { json_hash['name'] })
    end
  end
end
