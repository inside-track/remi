Feature: This tests the creation of example records.

  Background:
    Given the job is 'Copy Source'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'

  Scenario: Simple example record loads in the source and is directly copied to target.

    Given the following example record for 'Source Data':
      | MyField    | MyOtherField |
      | Remilspot  | Niblet       |
    Then the target field 'MyField' is set to the value "Remilspot"
    And the target field 'MyOtherField' is set to the value "Niblet"

  Scenario: Handling date formulas in the example data with day units.

    Given the following example record for 'Source Data':
      | Yesterday   | ThreeDaysFromNow  |
      | *Yesterday* | *3 days from now* |
    Then the target field 'Yesterday' is the date 1 day ago
    And the target field 'ThreeDaysFromNow' is the date 3 days from now
