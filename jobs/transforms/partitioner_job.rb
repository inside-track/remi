require_relative '../all_jobs_shared'

class PartitionerJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :id      => {}
    }

  define_source :distribution, Remi::DataSource::DataFrame,
    fields: {
      :group  => {},
      :weight => {}
    }

  define_source :current_population, Remi::DataSource::DataFrame,
    fields: {
      :group => {},
      :count => {}
    }

  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do

    distribution_hash = distribution.df.map(:row) { |row| [row[:group], row[:weight].to_f] }.to_h
    current_population_hash = current_population.df.map(:row) { |row| [row[:group], row[:count].to_i] }.to_h

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map target(:group)
        .transform(Remi::Transform::Partitioner.new(buckets: distribution_hash, initial_population: current_population_hash))
    end
  end
end
