Feature: Test the NVL (Next Value Lookup) transformer.

  Background:
    Given the job is 'Nvl'
    And the job source 'Source Data'
    And the job target 'Target Data'

  Scenario Outline: Performing an NVL
    Given the source 'Source Data'
    And the target 'Target Data'

    And the source field 'Field1' is set to the value "<Field1>"
    And the source field 'Field2' is set to the value "<Field2>"
    And the source field 'Field3' is set to the value "<Field3>"
    And the job parameter 'default' is "<Default>"
    Then the target field 'Result Field' is set to the value "<Expected>"

    Examples:
      | Field1 | Field2 | Field3 | Default | Expected |
      | A      | B      | C      |         | A        |
      |        | B      | C      |         | B        |
      |        |        | C      |         | C        |
      |        |        |        |         |          |
      |        |        |        | UNK     | UNK      |


  Scenario: Testing an NVL with the short form version
    Given the source 'Source Data'
    And the target 'Target Data'

    Then the target field 'Result Field' is the first non-blank value from source fields 'Field1', 'Field2', 'Field3'

  @fails
  Scenario: Testing an NVL with the short form version in the wrong order
    Given the source 'Source Data'
    And the target 'Target Data'

    Then the target field 'Result Field' is the first non-blank value from source fields 'Field2', 'Field1', 'Field3'
