Feature: This tests aspects of stubbing data used in tests.

  Background:
    Given the job is 'Stubbed Data'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'


  Scenario: Stubbed data should be unique row-by-row

    Given the following example records for 'Source Data':
      | col1 |
      | 1    |
      | 2    |
      | 3    |

    Then the target field 'col1' contains unique values
    And the target field 'col2' contains unique values

  @fails
  Scenario: Test that uniqueness will fail

    Given the following example records for 'Source Data':
      | col1 |
      | A    |
      | A    |
      | A    |

    Then the target field 'col1' contains unique values
