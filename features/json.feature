Feature: This tests using json data in tests.

  Background:
    Given the job is 'Json'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'

  Scenario: Using JSON data in an example record.

    Given the following example record for 'Source Data':
      | json_array       | json_hash            |
      | [ "one", "two" ] | { "name": "Darwin" } |

    Then the target field 'second_element' is populated with "two"
    And the target field 'name_field' is populated with "Darwin"


  Scenario: Using JSON data in long form

    Given the source field 'json_hash' has the multiline value
      """
        {
          "id": 97,
          "name": "Darwin",
          "birthday": "1809-02-12"
        }
      """
    And the target field 'name_field' is populated with "Darwin"
