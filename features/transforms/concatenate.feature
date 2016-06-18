Feature: Test the concatenate transformer.

  Background:
    Given the job is 'Concatenate'
    And the job source 'Source Data'
    And the job target 'Target Data'

  Scenario Outline: Performing a concatenation
    Given the source 'Source Data'
    And the target 'Target Data'

    And the source field 'Field1' is set to the value "<Field1>"
    And the source field 'Field2' is set to the value "<Field2>"
    And the source field 'Field3' is set to the value "<Field3>"
    And the job parameter 'delimiter' is "<Delimiter>"
    Then the target field 'Result Field' is set to the value "<Expected>"

    Examples:
      | Field1 | Field2 | Field3 | Delimiter | Expected |
      | A      | B      | C      | ,         | A,B,C    |
      |        | B      | C      | -         | B-C      |
      |        |        | C      | ,         | C        |
      |        |        |        | ,         |          |


  Scenario: Testing a concatenation with the short form version
    Given the source 'Source Data'
    And the target 'Target Data'

    Then the target field 'Result Field' is a concatenation of the source fields 'Field1', 'Field2', 'Field3', delimited by ","
