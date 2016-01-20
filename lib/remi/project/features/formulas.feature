Feature: This tests the creation of example records.

  Background:
    Given the job is 'Copy Source'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'

  Scenario: Handling date formulas in the example data with day units.

    Given the following example record for 'Source Data':
      | Yesterday   | Tomorrow   | OneDayAgo   | SevenDaysAgo  | ThreeDaysFromNow  |
      | *Yesterday* | *Tomorrow* | *1 day ago* | *7 days ago*  | *3 days from now* |
    Then the target field 'Yesterday' is the date 1 day ago
    And the target field 'Tomorrow' is the date 1 day from now
    And the target field 'OneDayAgo' is the date 1 day ago
    And the target field 'SevenDaysAgo' is the date 7 days ago
    And the target field 'ThreeDaysFromNow' is the date 3 days from now

  Scenario: Handling date formulas in the example data with month units.

    Given the following example record for 'Source Data':
      | LastMonth    | NextMonth    | OneMonthAgo   | SevenMonthsAgo  | ThreeMonthsFromNow  |
      | *Last Month* | *Next Month* | *1 month ago* | *7 months ago*  | *3 months from now* |
    Then the target field 'LastMonth' is the date 1 month ago
    And the target field 'NextMonth' is the date 1 month from now
    And the target field 'OneMonthAgo' is the date 1 month ago
    And the target field 'SevenMonthsAgo' is the date 7 months ago
    And the target field 'ThreeMonthsFromNow' is the date 3 months from now

  Scenario: Handling date formulas in the example data with year units.

    Given the following example record for 'Source Data':
      | LastYear    | NextYear    | OneYearAgo   | SevenYearsAgo  | ThreeYearsFromNow  |
      | *Last Year* | *Next Year* | *1 year ago* | *7 years ago*  | *3 years from now* |
    Then the target field 'LastYear' is the date 1 year ago
    And the target field 'NextYear' is the date 1 year from now
    And the target field 'OneYearAgo' is the date 1 year ago
    And the target field 'SevenYearsAgo' is the date 7 years ago
    And the target field 'ThreeYearsFromNow' is the date 3 years from now

  Scenario: Handling date formulas in the example data with week units.

    Given the following example record for 'Source Data':
      | LastWeek    | NextWeek    | OneWeekAgo   | SevenWeeksAgo  | ThreeWeeksFromNow  |
      | *Last Week* | *Next Week* | *1 week ago* | *7 weeks ago*  | *3 weeks from now* |
    Then the target field 'LastWeek' is the date 1 week ago
    And the target field 'NextWeek' is the date 1 week from now
    And the target field 'OneWeekAgo' is the date 1 week ago
    And the target field 'SevenWeeksAgo' is the date 7 weeks ago
    And the target field 'ThreeWeeksFromNow' is the date 3 weeks from now

  Scenario: Handling date formulas when set explicitly in the source.

    Given the following example record for 'Source Data':
      | SomeDate   |
      | 2015-10-22 |
    And the source field 'SomeDate' is set to the value "*Yesterday*"
    Then the target field 'SomeDate' is the date 1 day ago

    When the source field 'SomeDate' is set to the value "*2 months from now*"
    Then the target field 'SomeDate' is the date 2 months from now
    Then the target field 'SomeDate' is populated with "*2 months from now*"
