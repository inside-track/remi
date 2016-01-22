Feature: Tests the aggregate refinement to the Daru library

  Background:
    Given the job is 'Aggregate'
    And the job source 'Source Data'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the target 'Target Data'

  Scenario: The aggregator should find the minimum year for each 'Alpha'
    Given the following example record for 'Source Data':
      | Alpha | Year | something |
      | a     | 2016 | 1 |
      | a     | 2018 | 1 |
      | b     | 2016 | 2 |
      | b     | 2010 | 3 |
      | a     | 2017 | 4 |
    And the following example record called 'expected result':
      | Alpha | Year |
      | a     | 2016 |
      | b     | 2010 |
    Then the target should match the example 'expected result'
