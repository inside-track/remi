# Auto-generated from Remi.  Editing this file is not recommended.  Instead,
# create another step definition file to contain application-specific steps.

### Job and background setup

Given /^the job is '([[:alnum:]\s]+)'$/ do |arg|
  @brt = Remi::BusinessRules::Tester.new(arg)
end

Given /^the job source '([[:alnum:]\s]+)'$/ do |arg|
  @brt.add_job_source arg
end

Given /^the job target '([[:alnum:]\s]+)'$/ do |arg|
  @brt.add_job_target arg
end

Given /^the following example record called '([[:alnum:]\s]+)':$/ do |arg, example_table|
  @brt.add_example arg, example_table
end

Given /^the job parameter '([[:alnum:]\s]+)' is "(.+)"$/ do |param, value|
  @brt.set_job_parameter(param, value)
end

### Setting up example data

Given /^the following example record for '([[:alnum:]\s]+)':$/ do |source_name, example_table|
  example_name = source_name
  @brt.add_example example_name, example_table
  @brt.job_sources[source_name].stub_data_with(@brt.examples[example_name])
end

Given /^the example '([[:alnum:]\s]+)' for '([[:alnum:]\s]+)'$/ do |example_name, source_name|
  @brt.job_sources[source_name].stub_data_with(@brt.examples[example_name])
end


### Source file processing

Given /^files with names matching the pattern \/(.*)\/$/ do |pattern|
  @brt.filestore.pattern(Regexp.new(pattern))
end

Given /^files with names that do not match the pattern \/(.*)\/$/ do |pattern|
  @brt.filestore.anti_pattern(Regexp.new(pattern))
end

Given /^files delivered within the last (\d+) hours$/ do |hours|
  @brt.filestore.delivered_since(Time.now - hours.to_i * 3600)
end

Given /^files were delivered more than (\d+) hours ago$/ do |hours|
  @brt.filestore.delivered_before(Time.now - hours.to_i * 3600)
end

Then /^the file with the latest date stamp will be downloaded for processing$/ do
  @brt.filestore.generate
  @brt.source.mock_extractor(@brt.filestore)
  expect(@brt.source.extract).to match_array Array(@brt.filestore.latest)
end

Then /^no files will be downloaded for processing$/ do
  @brt.filestore.generate
  @brt.source.mock_extractor(@brt.filestore)
  expect { @brt.source.extract }.to raise_error Remi::Extractor::SftpFile::FileNotFoundError
end


Given /^the source file is delimited with a (\w+)$/ do |delimiter|
  expect(@brt.source.csv_options[:col_sep]).to eq Remi::BusinessRules.csv_opt_map[delimiter]
end

Given /^the source file is encoded using "([^"]+)" format$/ do |encoding|
  expect(@brt.source.csv_options[:encoding].split(':').first).to eq encoding
end

Given /^the source file uses a ([\w ]+) to quote embedded delimiters$/ do |quote_char|
  expect(@brt.source.csv_options[:quote_char]).to eq Remi::BusinessRules.csv_opt_map[quote_char]
end

Given /^the source file uses a preceeding ([\w ]+) to escape an embedded quoting character$/ do |escape_char|
  expect(@brt.source.csv_options[:quote_char]).to eq Remi::BusinessRules.csv_opt_map[escape_char]
end

Given /^the source file uses ([\w ]+) line endings$/ do |line_endings|
  expect(@brt.source.csv_options[:row_sep]).to eq Remi::BusinessRules.csv_opt_map[line_endings]
end

Given /^the source file (contains|does not contain) a header row$/ do |header|
  expect(@brt.source.csv_options[:headers]).to eq (header == 'contains')
end

Given /^the source file contains at least the following headers in no particular order:$/ do |table|
  table.rows.each do |row|
    field = row.first
    step "the source field '#{field}'"
  end
  expect(@brt.source.data_obj.fields.keys).to include(*@brt.source.fields.names)
end


### Source

Given /^the source '([[:alnum:]\s]+)'$/ do |arg|
  @brt.add_source(arg)
end

Given /^the source field '(.+)'$/ do |arg|
  @brt.sources.add_field(arg)
end

Given /^the source field has the value "(.+)"$/ do |arg|
  @brt.source.field.value = arg
end

When /^the source field (?:has an empty value|is blank)$/ do
  @brt.source.field.value = ''
end

When /^the source field '(.+)' (?:has an empty value|is blank)$/ do |source_field|
  step "the source field '#{source_field}'"
  @brt.source.fields[source_field].value = ''
end

Given /^the source field '([^:]+)' (?:has|is set to) the value "(.+)"$/ do |source_field, value|
  step "the source field '#{source_field}'"
  @brt.source.fields[source_field].value = value
end

Given /^the source field '(.+:.+)' (?:has|is set to) the value "(.+)"$/ do |source_field, value|
  step "the source field '#{source_field}'"
  source_name, field_name = *Remi::BusinessRules.parse_full_field(source_field)
  @brt.sources[source_name].fields[field_name].value = value
end

Given /^the source field '(.+:.+)' (?:has|is set to) the value in the source field '(.+:.+)', prefixed with "(.+)"$/ do |source_field, other_source_field, prefix|
  step "the source field '#{source_field}'"
  step "the source field '#{other_source_field}'"
  source_name, field_name = *Remi::BusinessRules.parse_full_field(source_field)
  other_source_name, other_field_name = *Remi::BusinessRules.parse_full_field(other_source_field)

  prefixed = "#{prefix}#{@brt.sources[other_source_name].fields[other_field_name].value}"
  @brt.sources[source_name].fields[field_name].value = prefixed
end

Given /^the source field is parsed with the date format "([^"]*)"$/ do |date_format|
  expect(@brt.source.field.metadata[:format]).to eq date_format
end

Given /^the source field is a valid email address$/ do
  @brt.source.field.value = 'valid@example.com'
end

Given /^the source field is not a valid email address$/ do
  @brt.source.field.value = 'invalid!example.com'
end

### Target

Given /^the target '([[:alnum:]\s]+)'$/ do |arg|
  @brt.add_target(arg)
end

Given /^the target field '([^']+)'$/ do |arg|
  @brt.targets.add_field(arg)
end

Then /^the target field '(.+)' is copied from the source field$/ do |arg|
  step "the target field '#{arg}'"
  step "the target field is copied from the source field"
end

Then /^the target field is copied from the source field$/ do
  @brt.run_transforms
  expect(@brt.target.field.value).to eq (@brt.source.field.value)
end

Then /^the target field '(.+)' is copied from the source field '(.+:.+)'$/ do |target_field, source_field|
  step "the target field '#{target_field}'"
  step "the source field '#{source_field}'"

  source_name, source_field_name = *Remi::BusinessRules.parse_full_field(source_field)

  @brt.run_transforms
  expect(@brt.target.field.value).to eq (@brt.sources[source_name].fields[source_field_name].value)
end

Then /^the target field is (?:set to the value|populated with) "([^"]*)"$/ do |value|
  @brt.run_transforms
  expect(@brt.target.field.value).to eq value
end

Then /^the target field '(.+)' is (?:set to the value|populated with) "([^"]*)"$/ do |target_field, value|
  @brt.targets.add_field(target_field)
  @brt.run_transforms
  expect(@brt.targets.fields.values.uniq).to eq [[value]]
end




### Transforms

Then /^the target field is a concatenation of the source fields, delimited by "([^"]*)"$/ do |delimiter|
  concatenated_source = @brt.sources.fields.values.uniq.map do |row|
    Array(row.join(delimiter))
  end

  @brt.run_transforms
  expect(@brt.targets.fields.values.uniq).to eq concatenated_source
end

Then /^the target field is a concatenation of "(.+)" and '(.+)', delimited by "([^"]*)"$/ do |constant, source_field, delimiter|
  expected_value = [constant, @brt.sources.fields[source_field].value].join(delimiter)
  @brt.run_transforms
  expect(@brt.targets.fields.values.uniq).to eq [[expected_value]]
end

Then /^the target field is a concatenation of '(.+)' and "(.+)", delimited by "([^"]*)"$/ do |source_field, constant, delimiter|
  expected_value = [@brt.sources.fields[source_field].value, constant].join(delimiter)
  @brt.run_transforms
  expect(@brt.targets.fields.values.uniq).to eq [[expected_value]]
end

Then /^the source field is prefixed with "([^"]*)" and loaded into the target field$/ do |prefix|
  prefixed_source = "#{prefix}#{@brt.source.field.value}"
  @brt.run_transforms
  expect(@brt.target.field.value).to eq prefixed_source
end

Then /^the target field '(.+)' is populated from the source field using the format "([^"]*)"$/ do |target_field, target_format|
  source_format = @brt.source.field.metadata[:format]
  source_reformatted = Remi::Transform[:format_date].(from_fmt: source_format, to_fmt: target_format)
    .call(@brt.source.field.value)

  step "the target field '#{target_field}'"
  @brt.run_transforms
  expect(@brt.target.field.value).to eq source_reformatted
end

Then /^the target field '(.+)' is populated with "([^"]*)" using the format "([^"]*)"$/ do |target_field, target_value, target_format|
  source_format = @brt.source.field.metadata[:format]
  target_value_source_format = target_value == "*Today's Date*" ? Date.today.strftime(source_format) : target_value
  target_reformatted = Remi::Transform[:format_date].(from_fmt: source_format, to_fmt: target_format)
   .call(target_value_source_format)

  step "the target field '#{target_field}'"
  @brt.run_transforms
  expect(@brt.target.field.value).to eq target_reformatted
end


When /^in the source field, periods have been used in place of commas$/ do
  @brt.source.field.value = @brt.source.field.value.gsub(/\./, ',')
end

Then /^the target field is copied from the source field, but commas have been replaced by periods$/ do
  source_field_value = @brt.source.field.value

  @brt.run_transforms
  expect(@brt.target.field.value).to eq source_field_value.gsub(/,/, '.')
end


### Field presence

Then /^only the following fields should be present on the target:$/ do |table|
  table.rows.each do |row|
    field = row.first
    step "the target field '#{field}'"
  end

  @brt.run_transforms
  expect(@brt.target.data_obj.fields.keys).to match_array @brt.target.fields.names
end

### Record-level expectations

Then /^the record should be (?i)(Retained|Rejected)(?-i)(?: without error|)$/ do |action|
  source_size  = @brt.source.size
  @brt.run_transforms
  targets_size = @brt.targets.total_size

  case
  when action.downcase == 'retained'
    expect(targets_size).to eq source_size
  when action.downcase == 'rejected'
    expect(targets_size).to eq 0
  else
    raise "Unknown action #{action}"
  end
end

Then /^a target record is created$/ do
  @brt.run_transforms
  expect(@brt.targets.total_size).to be > 0
end

Then /^a target record is not created$/ do
  @brt.run_transforms
  expect(@brt.targets.total_size).to be 0
end
