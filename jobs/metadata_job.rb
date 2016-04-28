require_relative 'all_jobs_shared'

class MetadataJob
  include AllJobsShared

  define_source :source_data, Remi::DataSource::DataFrame,
    fields: {
      :activity_id      => { from: 'in', in: true, cdc_type: 2 },
      :student_id       => { from: 'in', in: true, type: :string, cdc_type: 2 },
      :student_dob      => { from: 'in', in: true, type: :date, in_format: '%m/%d/%Y', out_format: '%Y-%m-%d', cdc_type: 2 },
      :activity_type    => { from: 'in', in: true, type: :string, valid_values: ['A', 'B', 'C'], cdc_type: 2 },
      :activity_counter => { from: 'in', in: true, type: :integer, cdc_type: 2 },
      :activity_score   => { from: 'in', in: true, type: :float, cdc_type: 2 },
      :activity_cost    => { from: 'in', in: true, type: :decimal, precision: 16, scale: 2, cdc_type: 2 },
      :activity_date    => { from: 'in', in: true, type: :datetime, in_format: '%m/%d/%Y %H:%M:%S', out_format: '%Y-%m-%dT%H:%M:%S', cdc_type: 2 },
      :source_filename  => { from: 'in', in: true, type: :string, cdc_type: 1 }
    }

  define_target :target_data, Remi::DataTarget::CsvFile,
    path: "#{Remi::Settings.work_dir}/target_data.csv",
    fields: {
      :activity_id      => { from: 'out', out: true },
      :student_id       => { from: 'out', out: true, type: :string },
      :student_dob      => { from: 'out', out: true, type: :date, in_format: '%m/%d/%Y', out_format: '%Y-%m-%d' },
      :activity_type    => { from: 'out', out: true, type: :string, valid_values: ['A', 'B', 'C'] },
      :activity_counter => { from: 'out', out: true, type: :integer },
      :activity_score   => { from: 'out', out: true, type: :float },
      :activity_cost    => { from: 'out', out: true, type: :decimal, precision: 16, scale: 2 },
      :activity_date    => { from: 'out', out: true, type: :datetime, in_format: '%m/%d/%Y %H:%M:%S', out_format: '%Y-%m-%dT%H:%M:%S' },
      :source_filename  => { from: 'out', out: true, type: :string, cdc_type: 1 }
    }

  define_transform :main do

=begin
    source_data.df = Remi::DataFrame.daru([
      ['1','1','3/3/1998','A','1','3.8','12.23','1/3/2016 03:22:36','one.csv'],
      ['2','1','3/3/1998','B','3','4.2','10.53','1/3/2016 03:58:22','one.csv'],
      ['2','1','','B','2','4.23','10.539','1/3/2016 03:58:22','one.csv']
    ].transpose, order: [
      :activity_id,
      :student_id,
      :student_dob,
      :activity_type,
      :activity_counter,
      :activity_score,
      :activity_cost,
      :activity_date,
      :source_filename
    ])
=end

    Remi::SourceToTargetMap.apply(source_data.df, target_data.df, source_metadata: source_data.fields) do
      target_data.fields.keys.each do |field|
        map source(field) .target(field)
          .transform(Remi::Transform::EnforceType.new)
      end
    end
  end
end
