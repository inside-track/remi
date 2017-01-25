Feature: This tests the creation of example records.
  The job that runs does nothing but copy source data to target.

  Background:
    Given the job is 'Copy Source'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'

  Scenario: Handling date formulas in the example data with minute units.

    Given the following example record for 'Source Data':
      | 1MinuteAgo     | 15MinutesAgo     | OneMinuteAgo      | 1MinuteFromNow      |  15MinutesFromNow      |
      | *1 minute ago* | *15 minutes ago* | *1 minute ago*    | *1 minute from now* | *15 minutes from now*  |
    Then the target field '1MinuteAgo' is the time 1 minute ago
    And the target field '2MinutesAgo' is the time 15 minutes from now
    And the target field 'OneMinuteAgo' is the time 1 minute ago
    And the target field '1MinuteFromNow' is the time 1 minute from now
    And the target field '2MinutesFromNow' is the time 15 minutes from now

  Scenario: Handling date formulas in the example data with hour units.

    Given the following example record for 'Source Data':
      | 1HourAgo     | 2HoursAgo     | OneHourAgo      | 1HourFromNow      |  2HoursFromNow      |
      | *1 hour ago* | *2 hours ago* | *1 hour ago*    | *1 hour from now* | *2 hours from now*  |
    Then the target field '1HourAgo' is the time 1 hour ago
    And the target field '2HoursAgo' is the time 2 hours from now
    And the target field 'OneHourAgo' is the time 1 hour ago
    And the target field '1HourFromNow' is the time 1 hour from now
    And the target field '2HoursFromNow' is the time 2 hours from now

  Scenario: Handling date formulas in the example data with day units.

    Given the following example record for 'Source Data':
      | Today   | Yesterday   | Tomorrow   | OneDayAgo   | SevenDaysAgo  | ThreeDaysFromNow  |
      | *Today* | *Yesterday* | *Tomorrow* | *1 day ago* | *7 days ago*  | *3 days from now* |
    Then the target field 'Today' is the date 0 days ago
    And the target field 'Yesterday' is the date 1 day ago
    And the target field 'Tomorrow' is the date 1 day from now
    And the target field 'OneDayAgo' is the date 1 day ago
    And the target field 'SevenDaysAgo' is the date 7 days ago
    And the target field 'ThreeDaysFromNow' is the date 3 days from now

  Scenario: Handling date formulas in the example data with month units.

    Given the following example record for 'Source Data':
      | ThisMonth    | LastMonth    | NextMonth    | OneMonthAgo   | SevenMonthsAgo  | ThreeMonthsFromNow  |
      | *This Month* |*Last Month* | *Next Month* | *1 month ago* | *7 months ago*  | *3 months from now* |
    Then the target field 'ThisMonth' is the date 0 months ago
    And the target field 'LastMonth' is the date 1 month ago
    And the target field 'NextMonth' is the date 1 month from now
    And the target field 'OneMonthAgo' is the date 1 month ago
    And the target field 'SevenMonthsAgo' is the date 7 months ago
    And the target field 'ThreeMonthsFromNow' is the date 3 months from now

  Scenario: Handling date formulas in the example data with year units.

    Given the following example record for 'Source Data':
      | ThisYear    | LastYear    | NextYear    | OneYearAgo   | SevenYearsAgo  | ThreeYearsFromNow  |
      | *This Year* | *Last Year* | *Next Year* | *1 year ago* | *7 years ago*  | *3 years from now* |
    Then the target field 'ThisYear' is the date 0 years ago
    And the target field 'LastYear' is the date 1 year ago
    And the target field 'NextYear' is the date 1 year from now
    And the target field 'OneYearAgo' is the date 1 year ago
    And the target field 'SevenYearsAgo' is the date 7 years ago
    And the target field 'ThreeYearsFromNow' is the date 3 years from now

  Scenario: Handling date formulas in the example data with week units.

    Given the following example record for 'Source Data':
      | ThisWeek    | LastWeek    | NextWeek    | OneWeekAgo   | SevenWeeksAgo  | ThreeWeeksFromNow  |
      | *This Week* | *Last Week* | *Next Week* | *1 week ago* | *7 weeks ago*  | *3 weeks from now* |
    Then the target field 'ThisWeek' is the date 0 week ago
    And the target field 'LastWeek' is the date 1 week ago
    And the target field 'NextWeek' is the date 1 week from now
    And the target field 'OneWeekAgo' is the date 1 week ago
    And the target field 'SevenWeeksAgo' is the date 7 weeks ago
    And the target field 'ThreeWeeksFromNow' is the date 3 weeks from now

  Scenario: Handling date formulas when set outside of a data example.

    Given the source field 'Some Date' is set to the value "*Yesterday*"
    Then the target field 'Some Date' is the date 1 day ago

    When the source field 'Some Date' is set to the value "*2 months from now*"
    Then the target field 'Some Date' is the date 2 months from now
    Then the target field 'Some Date' is populated with "*2 months from now*"

  Scenario: Handling a date formula that is embedded in a larger string.
    Given the following example record for 'Source Data':
      | Some Date | Some String | Combination       |
      | *Today*   | Something   | *Today*-Something |
    And the source field 'Some Date'
    And the source field 'Some String'
    And the target field 'Combination'
    Then the target field 'Combination' is a concatenation of the source fields 'Some Date' and 'Some String', delimited by "-"
    Then the target field 'Combination' is a concatenation of the source fields, delimited by "-"
