Feature: This is a job that demonstrates how to use Remi sub transforms

  Background:
    Given the job is 'Sub Transform Example'
    And the job source 'My Source'
    And the job target 'My Target'

  Scenario: It uses the subtransform to prefix a field with the default value

    Given the source 'My Source'
    And the target 'My Target'

    And the following example for 'My Source':
      | id |
      | 1  |

    Then the target should match the example:
      | id | default_id |
      | 1  | DEFAULT1   |


  Scenario: It uses parameters to customize subtansforms

    Given the source 'My Source'
    And the target 'My Target'

    And the job parameter 'job_prefix' is "UC"

    And the following example for 'My Source':
      | id |
      | 1  |

    Then the target should match the example:
      | id | default_id |
      | 1  | UC1        |
