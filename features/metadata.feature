Feature: This tests the application of metadata.
  We need some additional tests to check for errors in parsing.


  Background:
    Given the job is 'Metadata'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'

    And the following example record for 'Source Data':
      | activity_id | student_id | student_dob | activity_type | activity_counter | activity_score | activity_cost | activity_date     | source_filename |
      |           1 |          1 |    3/3/1998 |             A |                1 |            3.8 |         12.23 | 1/3/2016 03:22:36 |         one.csv |

  Scenario: Metadata is used to parse date fields
    Then the target field 'student_dob' is set to the value "1998-03-03"
