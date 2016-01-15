Feature: Test the prefixer transformer.

  Background:
    Given the job is 'Prefix'
    And the job source 'Source Data'
    And the job target 'Target Data'


  Scenario: Prefixing a field.
    Given the source 'Source Data'
    And the target 'Target Data'
    Given the following example record for 'Source Data':
      | Field     |
      | something |
    Then the target field 'Field' is set to the value "prefixsomething"
