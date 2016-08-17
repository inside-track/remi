require_relative 'all_jobs_shared'

class CsvFileTargetJob < Remi::Job
  target :some_csv_file do
    encoder Remi::Encoder::CsvFile.new(
      path: "#{Remi::Settings.work_dir}/some_file.csv",
      csv_options: {
        col_sep: '|'
      }
    )
  end

  transform :main do
    some_csv_file.df = Daru::DataFrame.new({
      col3: Faker::Hipster.words(10),
      col1: Faker::Hipster.words(10),
      col2: ["uh, \"oh"] + Faker::Hipster.words(9)
    }, order: [:col3, :col1, :col2])
  end
end
