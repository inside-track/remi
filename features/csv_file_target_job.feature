Feature: Tests targets that are Csv Files.

  Background:
    Given the job is 'Csv File Target'
    And the job target 'Some Csv File'


  Scenario: Defining target csv options.

    Given the target 'Some Csv File'
    And the target file is delimited with a pipe
    And the target file is encoded using "UTF-8" format
    And the target file uses a double quote to quote embedded delimiters
    And the target file uses a preceding double quote to escape an embedded quoting character
    And the target file uses unix line endings
    And the target file contains a header row
    And the target file contains all of the following headers in this order:
      | header |
      | col3   |
      | col1   |
      | col2   |
