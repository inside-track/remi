require_relative 'all_jobs_shared'

class BeersJob < Remi::Job
  source :beers do
    extractor Remi::Extractor::DataFrame.new(
      data: [
        [ 'Baerlic', 'IPA' ],
        [ 'Ex Novo', 'Red' ]
      ]
    )
    parser Remi::Parser::DataFrame.new
    fields(
      {
        brewer: {},
        style: {}
      }
    )
  end

  transform :main do
    # In the real world, add lots of complex stuff here, possibly grabbing
    # from multiple sources.
    beers.df
  end
end

class ZombifyJob < Remi::Job
  source :beers
  target :zombie_beers

  transform :main do
    Remi::SourceToTargetMap.apply(beers.df, zombie_beers.df) do
      map source(:brewer) .target(:brewer)
        .transform(Remi::Transform::Prefix.new('Zombie '))
      map source(:style) .target(:style)
        .transform(Remi::Transform::Prefix.new('Zombie '))
    end
  end
end

class SubJobExampleJob < Remi::Job
  sub_job(:beers_job) { BeersJob.new }
  sub_job(:zombify_job) { ZombifyJob.new }

  # This originates from a source in the sub job
  source :beer_fridge do
    extractor Remi::Extractor::SubJob.new(
      sub_job: beers_job,
      data_subject: :beers
    )
    fields beers_job.fields :beers
  end

  # This target is used as a source in the sub job
  target :beers_to_zombify do
    loader Remi::Loader::SubJob.new(
      sub_job: zombify_job,
      data_subject: :beers
    )
  end

  # This source is obtained from the target of the sub job
  source :zombie_fridge do
    extractor Remi::Extractor::SubJob.new(
      sub_job: zombify_job,
      data_subject: :zombie_beers
    )
    fields zombify_job.fields :zombie_beers
  end

  # These are the ultimate targets of this job
  target :just_beers
  target :zombified_beers

  transform :zombification do
    # Sub jobs are executed when data from a sub job is requested
    # Here, the sub job beers_job is executed
    just_beers.df = beer_fridge.df

    # Data is supplied to the sub job on assignment
    beers_to_zombify.df = just_beers.df

    # Here, the sub job zombify_job is executed using the data supplied to it above
    zombified_beers.df = zombie_fridge.df
  end
end
