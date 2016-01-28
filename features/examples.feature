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

  Scenario: Counting the number of records.
    Given the following example record for 'Source Data':
      | Id | Name  |
      | 1  | Alpha |
      | 2  | Beta  |
      | 3  | Gamma |
    Then the target has 3 records
    Then the target 'Target Data' has 3 records

  Scenario: Counting the number of recors that satisfy some condition.
    Given the following example record for 'Source Data':
      | Id | Name    | Category | Quantity |
      | 1  | Alpha   | Small    | 0.5      |
      | 2  | Beta    | Small    | 0.7      |
      | 3  | Gamma   | Big      | 30       |
      | 4  | Delta   | Big      | 38       |
      | 5  | Epsilon | Normal   | 1        |
    Then the target has 2 records where 'Category' is "Small"
    And the target has 3 records where 'Category' is in "Small, Normal"
    And the target has 1 record where 'Quantity' is 0.7
    And the target has 2 records where 'Quantity' is less than 1
    And the target has 3 records where 'Quantity' is greater than 0.9
    And the target has 3 records where 'Quantity' is between 0 and 1
    And the target has 2 records where 'Quantity' is between 0.6 and 2
