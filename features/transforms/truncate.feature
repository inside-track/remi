Feature: Test the truncate transformer.

  Background:
    Given the job is 'Truncate'
    And the job source 'Source Data'
    And the job target 'Target Data'

  Scenario: Truncating a field.
    Given the source 'Source Data'
    And the target 'Target Data'
    And the job parameter 'truncate_len' is "5"

    And the source field 'My Field' is set to the value "something"
    Then the target field 'Truncated Field' is set to the value "somet"

    And the job parameter 'truncate_len' is "7"

    And the source field 'My Field' is set to the value "something"
    Then the target field 'Truncated Field' is set to the value "somethi"
