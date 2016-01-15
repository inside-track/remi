Feature: Tests the date_diff transformer

  Background:
    Given the job is 'DateDiff'
    And the job source 'Source Data'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the target 'Target Data'
    And the following example record for 'Source Data':
      | Date1      | Date2      |
      | 2015-12-31 | 2016-01-02 |

  Scenario Outline: Calculating date difference in days2.
    Given the job parameter 'measure' is "days"
    And the source field 'Date1' has the value "<Date1>"
    And the source field 'Date2' has the value "<Date2>"
    Then the target field 'Difference' is set to the value "<Difference>"
    Examples:
      | Date1      | Date2      | Difference |
      | 2015-12-31 | 2016-01-02 | 2          |
      | 2014-12-31 | 2015-12-31 | 365        |
      | 2016-01-02 | 2015-12-31 | -2         |
      | 2015-02-28 | 2015-03-01 | 1          |
      | 2016-02-28 | 2016-03-01 | 2          | # leap day


  Scenario Outline: Calculating date difference in months.
    Given the job parameter 'measure' is "months"
    And the source field 'Date1' has the value "<Date1>"
    And the source field 'Date2' has the value "<Date2>"
    Then the target field 'Difference' is set to the value "<Difference>"
    Examples:
      | Date1      | Date2      | Difference |
      | 2015-12-31 | 2016-01-02 | 1          |
      | 2015-12-31 | 2016-02-02 | 2          |
      | 2015-12-31 | 2017-02-02 | 14         |
      | 2016-02-02 | 2015-12-31 | -2         |

  Scenario Outline: Calculating date difference in years.
    Given the job parameter 'measure' is "years"
    And the source field 'Date1' has the value "<Date1>"
    And the source field 'Date2' has the value "<Date2>"
    Then the target field 'Difference' is set to the value "<Difference>"
    Examples:
      | Date1      | Date2      | Difference |
      | 2015-12-31 | 2016-01-02 | 1          |
      | 2015-01-01 | 2015-12-31 | 0          |
      | 2015-12-31 | 2017-02-02 | 2          |
      | 2016-02-02 | 2015-12-31 | -1         |
