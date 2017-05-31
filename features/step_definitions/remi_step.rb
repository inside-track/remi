# Auto-generated from Remi.  Editing this file is not recommended.  Instead,
# create another step definition file to contain application-specific steps.

### Job and background setup

Given /^the job is '([[:alnum:]\s]+)'$/ do |arg|
  @brt = Remi::Testing::BusinessRules::Tester.new(arg)
end

Given /^the job source '([[:alnum:]\s\-_]+)'$/ do |arg|
  @brt.add_job_source arg
end

Given /^the job target '([[:alnum:]\s\-_]+)'$/ do |arg|
  @brt.add_job_target arg
end

Given /^the job parameter '([[:alnum:]\s\-_]+)' is "([^"]*)"$/ do |param, value|
  @brt.set_job_parameter(param, value)
end

### Setting up example data

Given /^the following example(?: record| records|) called '([[:alnum:]\s\-_]+)':$/ do |arg, example_table|
  @brt.add_example arg, example_table
end

Given /^the following example(?: record| records|) for '([[:alnum:]\s\-_]+)':$/ do |source_name, example_table|
  example_name = SecureRandom.uuid
  @brt.add_example example_name, example_table
  @brt.job_sources[source_name].stub_data_with(@brt.examples[example_name])
end

Given /^the example '([[:alnum:]\s\-_]+)' for '([[:alnum:]\s\-_]+)'$/ do |example_name, source_name|
  @brt.job_sources[source_name].stub_data_with(@brt.examples[example_name])
end

Given /^the following (?:record is|records are) appended to '([[:alnum:]\s\-_]+)':$/ do |source_name, example_table|
  example_name = SecureRandom.uuid
  @brt.add_example example_name, example_table
  @brt.job_sources[source_name].append_data_with(@brt.examples[example_name])
end

### Source file processing

Given /^files with names matching the pattern \/(.*)\/$/ do |pattern|
  expect(@brt.source.data_subject.extractors.map(&:pattern)).to include Regexp.new(pattern)
end

Given /^download groups defined by the pattern \/(.*)\/$/ do |pattern|
  expect(@brt.source.data_subject.extractors.map(&:group_by)).to include Regexp.new(pattern)
end

Then /^the file with the latest date stamp will be downloaded for processing$/ do
  expect(@brt.source.data_subject.extractors.map(&:most_recent_by)).to include :create_time
end

Then /^all files matching the pattern will be downloaded for processing$/ do
  expect(@brt.source.data_subject.extractors.map(&:most_recent_only)).not_to include eq true
end

Then /^the file that comes last in an alphanumeric sort by group will be downloaded for processing$/ do
  expect(@brt.source.data_subject.extractors.map(&:most_recent_by)).to include :name
  expect(@brt.source.data_subject.extractors.map(&:most_recent_only)).not_to include false
end

Then /^the file is uploaded to the remote path "([^"]+)"$/ do |remote_path|
  expected_path = Remi::Testing::BusinessRules::ParseFormula.parse(remote_path)
  expect(@brt.target.data_subject.loaders.map(&:remote_path)).to include expected_path
end

## CSV Options

Given /^the (source|target) file is delimited with a (\w+)$/ do |st, delimiter|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:col_sep]).to eq Remi::Testing::BusinessRules.csv_opt_map[delimiter]
end

Given /^the (source|target) file is encoded using "([^"]+)" format$/ do |st, encoding|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:encoding].split(':').first).to eq encoding
end

Given /^the (source|target) file uses a ([\w ]+) to quote embedded delimiters$/ do |st, quote_char|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:quote_char]).to eq Remi::Testing::BusinessRules.csv_opt_map[quote_char]
end

Given /^the (source|target) file uses a preceding ([\w ]+) to escape an embedded quoting character$/ do |st, escape_char|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:quote_char]).to eq Remi::Testing::BusinessRules.csv_opt_map[escape_char]
end

Given /^the (source|target) file uses ([\w ]+) line endings$/ do |st, line_endings|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:row_sep]).to eq Remi::Testing::BusinessRules.csv_opt_map[line_endings]
end

Given /^the (source|target) file uses "([^"]+)" as a record separator$/ do |st, line_endings|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:row_sep]).to eq line_endings.gsub(/\\n/, "\n").gsub(/\\r/, "\r")
end

Given /^the (source|target) file (contains|does not contain) a header row$/ do |st, header|
  csv_subject = @brt.send(st.to_sym).data_subject.send(st == 'source' ? :parser : :encoder)
  expect(csv_subject.csv_options[:headers]).to eq (header == 'contains')
end

Given /^the (source|target) file contains at least the following headers in no particular order:$/ do |st, table|
  table.rows.each do |row|
    field = row.first
    step "the #{st} field '#{field}'"
  end
  expect(@brt.send(st.to_sym).data_subject.df.vectors.to_a).to include(*@brt.send(st.to_sym).fields.field_names)
end

Given /^the (source|target) file contains all of the following headers in this order:$/ do |st, table|
  table.rows.each do |row|
    field = row.first
    step "the #{st} field '#{field}'"
  end

  @brt.run_transforms if st == 'target'
  expect(@brt.send(st.to_sym).data_subject.df.vectors.to_a).to eq @brt.send(st.to_sym).fields.field_names
end

Given /^the (source|target) file contains all of the following headers in no particular order:$/ do |st, table|
  table.rows.each do |row|
    field = row.first
    step "the #{st} field '#{field}'"
  end

  @brt.run_transforms if st == 'target'
  expect(@brt.send(st.to_sym).data_subject.df.vectors.to_a).to match_array @brt.send(st.to_sym).fields.field_names
end

### Source

Given /^the source '([[:alnum:]\s\-_]+)'$/ do |arg|
  @brt.add_source(arg)
end

Given /^the source field '([^']+)'$/ do |source_field_name|
  @brt.sources.add_field(source_field_name)
end

Given /^the source field '([^']+)' (?:has|is set to) the value "([^"]*)"$/ do |source_field, value|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  @brt.sources[source_name].fields[source_field_name].value = Remi::Testing::BusinessRules::ParseFormula.parse(value)
end

Given /^the source field (?:has|is set to) the value "([^"]*)"$/ do |value|
  @brt.sources.fields.each do |field|
    step "the source field '#{field.full_name}' is set to the value \"#{value}\""
  end
end

Given /^the source field '([^']+)' (?:has|is set to) the multiline value$/ do |source_field, value|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  @brt.sources[source_name].fields[source_field_name].value = Remi::Testing::BusinessRules::ParseFormula.parse(value)
end

Given /^the source field (?:has|is set to) the multiline value$/ do |value|
  @brt.sources.fields.each do |field|
    step "the source field '#{field.full_name}' has the multiline value #{value}"
  end
end

When /^the source field '([^']+)' (?:has an empty value|is blank)$/ do |source_field|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)

  @brt.sources[source_name].fields[source_field_name].value = ''
end

When /^the source field (?:has an empty value|is blank)$/ do
  @brt.sources.fields.each do |field|
    step "the source field '#{field.full_name}' is blank"
  end
end

Given /^the source field '(.+:.+)' (?:has|is set to) the value in the source field '(.+:.+)'$/ do |source_field, other_source_field|
  step "the source field '#{source_field}'"
  step "the source field '#{other_source_field}'"
  source_name, field_name = @brt.sources.parse_full_field(source_field)
  other_source_name, other_field_name = @brt.sources.parse_full_field(other_source_field)

  @brt.sources[source_name].fields[field_name].value = @brt.sources[other_source_name].fields[other_field_name].value
end

Given /^the source field '(.+:.+)' (?:has|is set to) the value in the source field '(.+:.+)', prefixed with "([^"]*)"$/ do |source_field, other_source_field, prefix|
  step "the source field '#{source_field}'"
  step "the source field '#{other_source_field}'"
  source_name, field_name = @brt.sources.parse_full_field(source_field)
  other_source_name, other_field_name = @brt.sources.parse_full_field(other_source_field)

  prefixed = "#{prefix}#{@brt.sources[other_source_name].fields[other_field_name].value}"
  @brt.sources[source_name].fields[field_name].value = prefixed
end

Given /^the source data are tied through the fields '(.+:.+)' and '(.+:.+)'$/ do |source_field, other_source_field|
  step "the source field '#{other_source_field}' is set to the value in the source field '#{source_field}'"
end

Given /^the source field '([^']+)' is parsed with the date format "([^"]*)"$/ do |source_field, date_format|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  expect(@brt.sources[source_name].fields[source_field_name].metadata[:in_format]).to eq date_format
end

Given /^the source field is parsed with the date format "([^"]*)"$/ do |date_format|
  @brt.sources.fields.each do |field|
    step "the source field '#{field.full_name}' is parsed with the date format \"#{date_format}\""
  end
end

Given /^the source field is a valid email address$/ do
  @brt.source.field.value = 'valid@example.com'
end

Given /^the source field is not a valid email address$/ do
  @brt.source.field.value = 'invalid!example.com'
end

Given /^the source field '([^']+)' is a valid email address$/ do |source_field|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  @brt.sources[source_name].fields[source_field_name].value = 'valid@example.com'
end

Given /^the source field '([^']+)' is not a valid email address$/ do |source_field|
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  @brt.sources[source_name].fields[source_field_name].value = 'invalid!example.com'
end

### Target

Given /^the target '([[:alnum:]\s\-_]+)'$/ do |arg|
  @brt.add_target(arg)
end

Given /^the target field '([^']+)'$/ do |arg|
  @brt.targets.add_field(arg)
end

Then /^the target field '([^']+)' is copied from the source field '([^']+)'$/ do |target_field, source_field|
  step "the target field '#{target_field}'"
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  @brt.run_transforms
  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].value).to eq (@brt.sources[source_name].fields[source_field_name].value)
  end
end

Then /^the target field '([^']+)' has the label '([^']+)'$/ do |target_field, label|
  step "the target field '#{target_field}'"
  data_field  = @brt.targets.fields.next
  expect(data_field.metadata[:label]).to eq label
  expect(data_field.name).to eq target_field

end

Then /^the target field '([^']+)' is copied from the source field$/ do |target_field|
  @brt.sources.fields.each do |source_field|
    step "the target field '#{target_field}' is copied from the source field '#{source_field.full_name}'"
  end
end

Then /^the target field is copied from the source field '([^']+)'$/ do |source_field|
  @brt.targets.fields.each do |target_field|
    step "the target field '#{target_field.full_name}' is copied from the source field '#{source_field}'"
  end
end

Then /^the target field is copied from the source field$/ do
  @brt.targets.fields.each do |target_field|
    @brt.sources.fields.each do |source_field|
      step "the target field '#{target_field.full_name}' is copied from the source field '#{source_field.full_name}'"
    end
  end
end

Then /^the target field '([^']+)' is (?:set to the value|populated with) "([^"]*)"$/ do |target_field, value|
  value = value.gsub(/(\\n|\\t)/, '\n' => "\n", '\t' => "\t" )

  expect_cucumber {
    target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

    expect {
      Array(target_names).each do |target_name|
        @brt.targets[target_name].add_field(target_field_name)
      end
      @brt.run_transforms
    }.not_to raise_error
    Array(target_names).each do |target_name|
      expect(@brt.targets[target_name].fields[target_field_name].values.uniq).to eq [Remi::Testing::BusinessRules::ParseFormula.parse(value)]
    end
  }
end

Then /^the target field is (?:set to the value|populated with) "([^"]*)"$/ do |value|
  @brt.targets.fields.each do |field|
    step "the target field '#{field.full_name}' is populated with \"#{value}\""
  end
end


Then /^the target field '(.+)' has a value in the list "([^"]*)"$/ do |target_field, list|
  step "the target field '#{target_field}'"

  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  list_array = list.split(',').map(&:strip)
  @brt.run_transforms
  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field].values.uniq & list_array).to include(*@brt.targets[target_name].fields[target_field].values.uniq)
  end
end


Then /^the target field '(.+)' is the date (.+)$/ do |target_field, date_reference|
  step "the target field '#{target_field}' is set to the value \"*#{date_reference}*\""
end

Then /^the target '(.+)' should match the example '([[:alnum:]\-\s]+)'$/ do |target_name, example_name|
  @brt.run_transforms

  target_hash = @brt.targets[target_name].column_hash
  example_hash = @brt.examples[example_name].column_hash
  common_keys = target_hash.keys & example_hash.keys
  expect(common_keys).to match_array(example_hash.keys), <<-EOT
    Fields in example not found in target
    Example fields: #{example_hash.keys}
    Target fields: #{target_hash.keys}
    Missing fields: #{example_hash.keys - target_hash.keys}
  EOT

  target_to_compare = target_hash.select { |k,v| common_keys.include? k }
  target_to_compare.each do |k, v|
    target_to_compare[k] = v.map { |e| e.to_s }
  end

  example_to_compare = example_hash.select { |k,v| common_keys.include? k }

  expect(target_to_compare).to eq example_to_compare
end

Then /^the target should match the example '([[:alnum:]\-\s]+)'$/ do |example_name|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' should match the example '#{example_name}'"
end

Then /^the target '(.+)' should match the example:/ do |target_name, example_table|
  example_name = SecureRandom.uuid
  @brt.add_example example_name, example_table
  step "the target '#{target_name}' should match the example '#{example_name}'"
end

Then /^the target should match the example:/ do |example_table|
  example_name = SecureRandom.uuid
  @brt.add_example example_name, example_table
  step "the target should match the example '#{example_name}'"
end


Then /^the target field '(.+)' is populated from the source field '(.+)' after translating it according to:$/ do |target_field, source_field, translation_table|
  step "the target field '#{target_field}'"

  translation_table.rows.each do |translation_row|
    step "the source field '#{source_field}' is set to the value \"#{translation_row[0]}\""
    @brt.run_transforms
    expect(@brt.target.fields[target_field].value).to eq translation_row[1]
  end
end


### Transforms

Then /^the target field '([^']+)' is a concatenation of the source fields '(.+)', delimited by "([^"]*)"$/ do |target_field, source_field_list, delimiter|
  delimiter = delimiter.gsub(/(\\n|\\t)/, '\n' => "\n", '\t' => "\t" )
  source_fields = "'#{source_field_list}'".gsub(' and ', ', ').split(',').map do |field_with_quotes|
    full_field_name = field_with_quotes.match(/'(.+)'/)[1]

    source_name, field_name = @brt.sources.parse_full_field(full_field_name)
    { full_field_name: full_field_name, source: source_name, field: field_name }
  end

  concatenated_source = source_fields.map do |field|
    step "the source field '#{field[:full_field_name]}'"
    @brt.sources[field[:source]].fields[field[:field]].values.uniq
  end.join(delimiter)

  step "the target field '#{target_field}'"

  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  @brt.run_transforms
  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].values.uniq).to eq Array(concatenated_source)
  end
end

Then /^the target field '([^']+)' is a concatenation of the source fields, delimited by "([^"]*)"$/ do |target_field, delimiter|
  source_field_list = @brt.sources.fields.map do |field|
    "'#{field.full_name}'"
  end.join(',')

  step "the target field '#{target_field}' is a concatenation of the source fields #{source_field_list}, delimited by \"#{delimiter}\""
end

Then /^the target field is a concatenation of the source fields, delimited by "([^"]*)"$/ do |delimiter|
  @brt.targets.fields.each do |target_field|
    step "the target field '#{target_field.full_name}' is a concatenation of the source fields, delimited by \"#{delimiter}\""
  end
end


Then /^the target field '([^']+)' is a concatenation of "([^"]*)" and '(.+)', delimited by "([^"]*)"$/ do |target_field, constant, source_field, delimiter|
  step "the target field '#{target_field}'"

  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)
  source_name, source_field_name = @brt.sources.parse_full_field(source_field)

  expected_value = [constant, @brt.sources[source_name].fields[source_field_name].value].join(delimiter)
  @brt.run_transforms

  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].values.uniq).to eq Array(expected_value)
  end
end

Then /^the target field '([^']+)' is a concatenation of '(.+)' and "([^"]*)", delimited by "([^"]*)"$/ do |target_field, source_field, constant, delimiter|
  step "the target field '#{target_field}'"

  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)
  source_name, source_field_name = @brt.sources.parse_full_field(source_field)

  expected_value = [@brt.sources[source_name].fields[source_field_name].value, constant].join(delimiter)
  @brt.run_transforms

  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].values.uniq).to eq Array(expected_value)
  end
end

Then /^the target field is a concatenation of "([^"]*)" and '(.+)', delimited by "([^"]*)"$/ do |constant, source_field, delimiter|
  @brt.targets.fields.each do |target_field|
    step "the target field '#{target_field.full_name}' is a concatenation of \"#{constant}\" and '#{source_field}', delimited by \"#{delimiter}\""
  end
end

Then /^the target field is a concatenation of '(.+)' and "([^"]*)", delimited by "([^"]*)"$/ do |source_field, constant, delimiter|
  @brt.targets.fields.each do |target_field|
    step "the target field '#{target_field.full_name}' is a concatenation of '#{source_field}' and \"#{constant}\", delimited by \"#{delimiter}\""
  end
end

Then /^the source field '([^']+)' is prefixed with "([^"]*)" and loaded into the target field '([^']+)'$/ do |source_field, prefix, target_field|
  step "the target field '#{target_field}'"
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  prefixed_source = @brt.sources[source_name].fields[source_field_name].values.map do |value|
    "#{prefix}#{value}"
  end.uniq.sort

  @brt.run_transforms
  results = Array(target_names).map do |target_name|
    @brt.targets[target_name].fields[target_field_name].values.uniq
  end.flatten.uniq.sort

  expect(results).to eq prefixed_source
end

Then /^the source field is prefixed with "([^"]*)" and loaded into the target field '([^']+)'$/ do |prefix, target_field|
  @brt.sources.fields.each do |source_field|
    step "the source field '#{source_field.full_name}' is prefixed with \"#{prefix}\" and loaded into the target field '#{target_field}'"
  end
end

Then /^the source field '([^']+)' is prefixed with "([^"]*)" and loaded into the target field$/ do |source_field, prefix|
  @brt.targets.fields.each do |target_field|
    step "the source field '#{source_field}' is prefixed with \"#{prefix}\" and loaded into the target field '#{target_field.full_name}'"
  end
end

Then /^the source field is prefixed with "([^"]*)" and loaded into the target field$/ do |prefix|
  @brt.sources.fields.each do |source_field|
    @brt.targets.fields.each do |target_field|
      step "the source field '#{source_field.full_name}' is prefixed with \"#{prefix}\" and loaded into the target field '#{target_field.full_name}'"
    end
  end
end


Then /^the target field '([^']+)' is populated from the source field '([^']+)' using the format "([^"]*)"$/ do |target_field, source_field, target_format|
  step "the source field '#{source_field}'"
  step "the target field '#{target_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)
  inferred_type = target_format =~ /(%H|%M|%S)/ ? :datetime : :date

  source_format = @brt.sources[source_name].fields[source_field_name].metadata[:in_format]
  source_reformatted = Remi::Transform::FormatDate.new(in_format: source_format, out_format: target_format, type: inferred_type).to_proc
    .call(@brt.sources[source_name].fields[source_field_name].value)

  @brt.run_transforms
  target_names.each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].value).to eq source_reformatted
  end
end

Then /^the target field '([^']+)' is populated from the source field using the format "([^"]*)"$/ do |target_field, target_format|
  @brt.sources.fields.each do |source_field|
    step "the target field '#{target_field}' is populated from the source field '#{source_field.full_name}' using the format \"#{target_format}\""
  end
end

Then /^the target field '(.+)' is the first non-blank value from source fields '(.+)'$/ do |target_field_name, source_field_list|
  source_fields = "'#{source_field_list}'".split(',').map do |field_with_quotes|
    full_field_name = field_with_quotes.match(/'(.+)'/)[1]

    source_name, field_name = @brt.sources.parse_full_field(full_field_name)
    { full_field_name: full_field_name, source: source_name, field: field_name }
  end

  source_fields.each do |source_field|
    step "the source field '#{source_field[:full_field_name]}'"
  end
  step "the target field '#{target_field_name}'"

  source_fields.each do |source_field|
    @brt.run_transforms

    source_values = source_fields.map { |v_source_field| @brt.sources[v_source_field[:source]].fields[v_source_field[:field]].value }
    source_values_nvl = source_values.find { |arg| !arg.blank? }

    expect_cucumber { expect(@brt.target.fields[target_field_name].value).to eq source_values_nvl }
    @brt.sources[source_field[:source]].fields[source_field[:field]].value = ''
  end

end

When /^in the source field, periods have been used in place of commas$/ do
  @brt.source.field.value = @brt.source.field.value.gsub(/\./, ',')
end

Then /^the target field is copied from the source field, but commas have been replaced by periods$/ do
  source_field_value = @brt.source.field.value

  @brt.run_transforms
  expect(@brt.target.field.value).to eq source_field_value.gsub(/,/, '.')
end

Then /^the target field '([^']+)' contains a unique value matching the pattern \/(.*)\/$/ do |target_field, pattern|
  step "the target field '#{target_field}'"

  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)
  regex_pattern = Regexp.new(pattern)

  results = 1.upto(10).map do |iter|
    @brt.run_transforms

    Array(target_names).map do |target_name|
      @brt.targets[target_name].fields[target_field_name].values.uniq
    end.flatten
  end.flatten

  results.each do |result_value|
    expect(result_value).to match(regex_pattern)
  end

  expect(results.size).to eq results.uniq.size

end

Then /^the target field contains a unique value matching the pattern \/(.*)\/$/ do |pattern|
  @brt.targets.fields.each do |target_field|
    step "the target field '#{target_field.full_name}' contains a unique value matching the pattern /#{pattern}/"
  end
end

Then /^the source field '([^']+)' is truncated to (\d+) characters and loaded into the target field '([^']+)'$/ do |source_field, character_limit, target_field|
  step "the target field '#{target_field}'"
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  value = (@brt.sources[source_name].fields[source_field_name].value) * character_limit.to_i
  @brt.sources[source_name].fields[source_field_name].value = value

  truncated_source = value.slice(0, character_limit.to_i)
  @brt.run_transforms
  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].value).to eq truncated_source
  end
end

Then /^the source field '([^']+)' is name-cased and loaded into the target field '([^']+)'$/ do |source_field, target_field|
  step "the target field '#{target_field}'"
  step "the source field '#{source_field}'"

  source_name, source_field_name = @brt.sources.parse_full_field(source_field)
  target_names, target_field_name = @brt.targets.parse_full_field(target_field, multi: true)

  @brt.sources[source_name].fields[source_field_name].value = 'SCROOGE MCDUCK'
  @brt.run_transforms
  Array(target_names).each do |target_name|
    expect(@brt.targets[target_name].fields[target_field_name].value).to eq 'Scrooge McDuck'
  end
end

Then /^the source field is name-cased and loaded into the target field '([^']+)'$/ do |target_field|
  @brt.sources.fields.each do |source_field|
    step "the source field '#{source_field}' is name-cased and loaded into the target field '#{target_field}'"
  end
end

Then /^the source field '([^']+)' is name-cased and loaded into the target field$/ do |source_field|
  @brt.targets.fields.each do |target_field|
    step "the source field '#{source_field}' is name-cased and loaded into the target field '#{target_field}'"
  end
end

Then /^the source field is name-cased and loaded into the target field$/ do
  @brt.targets.fields.each do |target_field|
    @brt.sources.fields.each do |source_field|
      step "the source field '#{source_field}' is name-cased and loaded into the target field '#{target_field}'"
    end
  end
end

### Field presence

Then /^only the following fields should be present on the target:$/ do |table|
  table.rows.each do |row|
    field = row.first
    step "the target field '#{field}'"
  end

  @brt.run_transforms
  expect(@brt.target.data_subject.df.vectors.to_a).to match_array @brt.target.fields.field_names
end

Then /^only the following fields should be present on the targets:$/ do |table|
  table.rows.each do |row|
    field = row[0]
    targets = row[1].split(',')
    targets.each { |target| step "the target field '#{target}: #{field}'" }
  end

  @brt.run_transforms
  @brt.targets.keys.each do |target|
    expect(@brt.targets[target].data_subject.df.vectors.to_a).to match_array @brt.targets[target].fields.field_names
  end
end



### Record-level expectations

Then /^the record from source '(.+)' should be (?i)(Retained|Rejected)(?-i)(?: without error|)$/ do |source_name, action|
  source_size  = @brt.sources[source_name].size
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

Then /^the record(?:s|) should be (?i)(Retained|Rejected)(?-i)(?: without error|)$/ do |action|
  source_name = @brt.sources.keys.first
  step "the record from source '#{source_name}' should be #{action}"
end

Then /^the record(?:s|) should (not be|be) present on the target$/ do |action|
  map_action = { 'not be' => 'rejected', 'be' => 'retained' }
  step "the record should be #{map_action[action]}"
end

Then /^a target record is created$/ do
  @brt.run_transforms
  expect(@brt.targets.total_size).to be > 0
end

Then /^a target record is not created$/ do
  @brt.run_transforms
  expect(@brt.targets.total_size).to be 0
end


### Setting up data for multiple records

Given /^the source field '([^']+)' is a unique integer$/ do |source_field|
  step "the source field '#{source_field}'"
  source_name, source_field_name = @brt.sources.parse_full_field(source_field)

  @brt.sources[source_name].unique_integer_field(source_field_name)
end

### Record counting

Then /^the target has (\d+) record(?:s|)$/ do |nrecords|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records"
end

Then /^the targets have (\d+) record(?:s|)$/ do |nrecords|
  @brt.run_transforms

  obs_nrecords = @brt.targets.keys.reduce(0) { |sum, target_name| sum += @brt.targets[target_name].size }
  expect(obs_nrecords).to eq nrecords.to_i
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|)$/ do |target_name, nrecords|
  @brt.run_transforms
  expect(@brt.targets[target_name].size).to eq nrecords.to_i
end

Then /^the target has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is "([^"]*)"$/ do |nrecords, field_name, value|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records where '#{field_name}' is \"#{value}\""
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is "([^"]*)"$/ do |target_name, nrecords, field_name, value|
  @brt.run_transforms
  expect(@brt.targets[target_name].where_is(field_name, value).size).to eq nrecords.to_i
end

Then /^the target has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is in "([^"]*)"$/ do |nrecords, field_name, value|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records where '#{field_name}' is in \"#{value}\""
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is in "([^"]*)"$/ do |target_name, nrecords, field_name, value|
  @brt.run_transforms
  expect(@brt.targets[target_name].where_in(field_name, value).size).to eq nrecords.to_i
end

Then /^the target has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is (\d*\.?\d+)$/ do |nrecords, field_name, value|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records where '#{field_name}' is #{value}"
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is (\d*\.?\d+)$/ do |target_name, nrecords, field_name, value|
  @brt.run_transforms
  expect(@brt.targets[target_name].where_is(field_name, value).size).to eq nrecords.to_i
end

Then /^the target has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is (less|greater) than (\d*\.?\d+)$/ do |nrecords, field_name, direction, value|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records where '#{field_name}' is #{direction} than #{value}"
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is (less|greater) than (\d*\.?\d+)$/ do |target_name, nrecords, field_name, direction, value|
  @brt.run_transforms
  query_method = { 'less' => :where_lt, 'greater' => :where_gt }[direction]

  expect(@brt.targets[target_name].send(query_method, field_name, value).size).to eq nrecords.to_i
end

Then /^the target has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is between (\d*\.?\d+) and (\d*\.?\d+)$/ do |nrecords, field_name, low_value, high_value|
  target_name = @brt.targets.keys.first
  step "the target '#{target_name}' has #{nrecords} records where '#{field_name}' is between #{low_value} and #{high_value}"
end

Then /^the target '([[:alnum:]\s\-_]+)' has (\d+) record(?:s|) where '([[:alnum:]\s\-_]+)' is between (\d*\.?\d+) and (\d*\.?\d+)$/ do |target_name, nrecords, field_name, low_value, high_value|
  @brt.run_transforms
  expect(@brt.targets[target_name].where_between(field_name, low_value, high_value).size).to eq nrecords.to_i
end

Then /^the target field '([^']+)' (?:has|is set to) the multiline value$/ do |target_field, value|
  step "the target field '#{target_field}'"
  @brt.run_transforms
  target_name, target_field_name = @brt.targets.parse_full_field(target_field)
  expect(@brt.targets[target_name].fields[target_field_name].value).to eq Remi::Testing::BusinessRules::ParseFormula.parse(value)
end
