require_relative '../all_jobs_shared'

class PartitionerJob < Remi::Job

  source :source_data do
    fields(
      {
        :id      => {}
      }
    )
  end

  source :distribution do
    fields(
      {
        :group  => {},
        :weight => {}
      }
    )
  end

  source :current_population do
    fields(
      {
        :group => {},
        :count => {}
      }
    )
  end

  target :target_data

  transform :main do

    distribution_hash = distribution.df.map(:row) { |row| [row[:group], row[:weight].to_f] }.to_h
    current_population_hash = current_population.df.map(:row) { |row| [row[:group], row[:count].to_i] }.to_h

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map target(:group)
        .transform(Remi::Transform::Partitioner.new(buckets: distribution_hash, initial_population: current_population_hash))
    end
  end
end
