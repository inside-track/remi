Feature: Tests the aggregate refinement to the Daru library

  Background:
    Given the job is 'Aggregate'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the job target 'Multigroup Target Data'

    And the source 'Source Data'


  Scenario: The aggregator should find the minimum year for each 'Alpha'
    Given the target 'Target Data'
    And the following example record for 'Source Data':
      | Alpha | Beta | Year |
      | a     | aa   | 2016 |
      | a     | aa   | 2018 |
      | b     | bb   | 2016 |
      | b     | bb   | 2010 |
      | a     | ab   | 2017 |
    And the following example record called 'expected result':
      | Alpha | Year |
      | a     | Group a has a minimum value of 2016 |
      | b     | Group b has a minimum value of 2010 |
    Then the target should match the example 'expected result'


  Scenario: The aggregator should find the minimum year for each 'Alpha'
    Given the target 'Multigroup Target Data'
    And the following example record for 'Source Data':
      | Alpha | Beta | Year |
      | a     | aa   | 2016 |
      | a     | aa   | 2018 |
      | b     | bb   | 2016 |
      | b     | bb   | 2010 |
      | a     | ab   | 2017 |
    And the following example record called 'expected result':
      | Alpha | Beta | Year |
      | a     | aa   | Group ["a", "aa"] has a minimum value of 2016 |
      | a     | ab   | Group ["a", "ab"] has a minimum value of 2017 |
      | b     | bb   | Group ["b", "bb"] has a minimum value of 2010 |
    Then the target should match the example 'expected result'
