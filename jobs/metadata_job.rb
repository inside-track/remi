require_relative 'all_jobs_shared'
ENV['TZ'] = 'UTC'

class MetadataJob < Remi::Job
  source :source_data do
    fields(
      {
        :activity_id      => { from: 'in', in: true, cdc_type: 2 },
        :student_id       => { from: 'in', in: true, type: :string, cdc_type: 2 },
        :student_dob      => { from: 'in', in: true, type: :date, in_format: '%m/%d/%Y', out_format: '%Y-%m-%d', cdc_type: 2 },
        :activity_type    => { from: 'in', in: true, type: :string, valid_values: ['A', 'B', 'C'], cdc_type: 2 },
        :activity_counter => { from: 'in', in: true, type: :integer, cdc_type: 2 },
        :activity_score   => { from: 'in', in: true, type: :float, cdc_type: 2 },
        :activity_cost    => { from: 'in', in: true, type: :decimal, precision: 8, scale: 2, cdc_type: 2 },
        :activity_date    => { from: 'in', in: true, type: :datetime, in_format: '%m/%d/%Y %H:%M:%S', out_format: '%Y-%m-%dT%H:%M:%S', cdc_type: 2 },
        :source_filename  => { from: 'in', in: true, type: :string, cdc_type: 1 }
      }
    )
  end

  target :target_data do
    encoder Remi::Encoder::CsvFile.new path: "#{Remi::Settings.work_dir}/target_data.csv"

    fields(
      {
        :activity_id      => { from: 'out', out: true },
        :student_id       => { from: 'out', out: true, type: :string },
        :student_dob      => { from: 'out', out: true, type: :date, in_format: '%m/%d/%Y', out_format: '%Y-%m-%d' },
        :activity_type    => { from: 'out', out: true, type: :string, valid_values: ['A', 'B', 'C'] },
        :activity_counter => { from: 'out', out: true, type: :integer },
        :activity_score   => { from: 'out', out: true, type: :float },
        :activity_cost    => { from: 'out', out: true, type: :decimal, precision: 8, scale: 2 },
        :activity_date    => { from: 'out', out: true, type: :datetime, in_format: '%m/%d/%Y %H:%M:%S', out_format: '%Y-%m-%dT%H:%M:%S' },
        :source_filename  => { from: 'out', out: true, type: :string, cdc_type: 1 }
      }
    )
  end

  transform :main do
    source_data.enforce_types

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df, source_metadata: source_data.fields, target_metadata: target_data.fields) do
      target_data.fields.keys.each do |field|
        map source(field) .target(field)

        map source(field) .target("#{field}_class".to_sym)
          .transform(->(v) { v.class })
      end

      map source(:activity_cost) .target(:activity_cost_precision, :activity_cost_scale)
        .transform(->(row) {
          components = row[:activity_cost].to_s.split('.')
          row[:activity_cost_precision] = components.first.size
          row[:activity_cost_scale] = components.last.size
        })
    end
  end
end
