require_relative 'all_jobs_shared'

class CopySourceJob < Remi::Job
  source :source_data do
    fields(
      {
        :some_field => {},
        :some_date => { type: :date, format: '%Y-%m-%d' }
      }
    )
  end

  target :target_data

  transform :main do
    target_data.df = source_data.df.dup
  end
end
