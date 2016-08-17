require_relative '../all_jobs_shared'

class DataFrameSieveJob < Remi::Job

  source :source_data do
    fields(
      {
        :id      => {},
        :level   => {},
        :program => {},
        :contact => {}
      }
    )
  end

  source :sieve do
    fields(
      {
        :level   => {},
        :program => {},
        :contact => {},
        :group   => {}
      }
    )
  end

  target :target_data

  transform :main do
    # Hack to convert example to regex
    sieve.df[:program].recode! { |v| (v || '').match(/\A\/.*\/\Z/) ? /#{v[1...-1]}/ : v }

    target_data.df = source_data.df.dup
    Remi::SourceToTargetMap.apply(source_data.df, target_data.df) do
      map source(:level, :program, :contact) .target(:group)
        .transform(Remi::Transform::DataFrameSieve.new(sieve.df))
    end
  end
end
