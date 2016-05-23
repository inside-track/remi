require_relative '../all_jobs_shared'

class DataFrameSieveJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :id      => {},
      :level   => {},
      :program => {},
      :contact => {}
    }

  define_source :sieve, Remi::DataSource::DataFrame,
    fields: {
      :level   => {},
      :program => {},
      :contact => {},
      :group   => {}
    }

  define_target :target_data, Remi::DataTarget::DataFrame

  define_transform :main, sources: :source_data, targets: :target_data do

    # Hack to convert example to regex
    sieve.df[:program].recode! { |v| (v || '').match(/\A\/.*\/\Z/) ? /#{v[1...-1]}/ : v }

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:level, :program, :contact) .target(:group)
        .transform(Remi::Transform::DataFrameSieve.new(sieve.df))
    end
  end
end
