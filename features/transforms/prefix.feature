Feature: Test the prefix transformer.

  Background:
    Given the job is 'Prefix'
    And the job source 'Source Data'
    And the job target 'Target Data'

  Scenario: Prefixing a field.
    Given the source 'Source Data'
    And the target 'Target Data'
    And the source field 'My Field' is set to the value "something"
    Then the target field 'Prefixed Field' is set to the value "prefixsomething"
