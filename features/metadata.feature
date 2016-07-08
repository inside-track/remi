Feature: This tests the application of metadata.
  We need some additional tests to check for errors in parsing.


  Background:
    Given the job is 'Metadata'
    And the job source 'Source Data'
    And the job target 'Target Data'
    And the source 'Source Data'
    And the target 'Target Data'


  Scenario: Metadata is used to parse date fields

    Given the following example record for 'Source Data':
      | activity_id | student_id | student_dob | activity_type | activity_counter | activity_score | activity_cost | activity_date             | source_filename |
      |           1 |          1 |    3/3/1998 |             A |                1 |            3.8 |         12.23 | 1/3/2016 03:22:36         |         one.csv |

    Then the target should match the example:
      | activity_id | student_id | student_dob | activity_type | activity_counter | activity_score | activity_cost | activity_date             | source_filename |
      |           1 |          1 |  1998-03-03 |             A |                1 |            3.8 |         12.23 | 2016-01-03 03:22:36 +0000 |         one.csv |

  Scenario Outline: Metadata is used to stub records with values that conform to the metadata

    Then the target field '<Field>' is set to the value "<Class>"

    Examples:
      | Field                  | Class   |
      | activity_id_class      | String  |
      | student_id_class       | String  |
      | student_dob_class      | Date    |
      | activity_type_class    | String  |
      | activity_counter_class | Fixnum  |
      | activity_score_class   | Float   |
      | activity_cost_class    | Float   |
      | activity_date_class    | Time    |
      | source_filename_class  | String  |


  Scenario: Metadata for decimals is stubbed

    Then the target field 'activity_cost_precision' is populated with "8"
    And the target field 'activity_cost_scale' is populated with "2"