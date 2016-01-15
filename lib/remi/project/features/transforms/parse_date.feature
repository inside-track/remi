Feature: Tests the date_parser transformer

  Background:
    Given the job is 'ParseDate'
    And the job source 'Source Data'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the target 'Target Data'
    And the following example record for 'Source Data':
      | Date String |
      | 2015-12-31  |

  Scenario Outline: Parsing date strings.
    Given the source field 'Date String' has the value "<Date String>"
    And the job parameter 'format' is "<Format>"
    Then the target field 'Parsed Date' is set to the value "<Parsed Date>"
    Examples:
      | Date String | Format   | Parsed Date |
      | 2015-10-21  | %Y-%m-%d | 2015-10-21  |
      | 10/21/2015  | %m/%d/%Y | 2015-10-21  |
      | 20151021    | %Y%m%d   | 2015-10-21  |
