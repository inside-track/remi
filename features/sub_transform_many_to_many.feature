Feature: This is a job that demonstrates how to use Remi sub transforms

  Background:
    Given the job is 'Sub Transform Many To Many'
    And the job source 'Beer Fact'
    And the job source 'Beer Dim'
    And the job target 'Beer Count'
    And the job target 'Style Count'


  Scenario: It runs the subtransform as expected

    Given the source 'Beer Fact'
    And the source 'Beer Dim'
    And the target 'Beer Count'
    And the target 'Style Count'

    And the following example for 'Beer Fact':
      | fact_sk | beer_sk |
      | 1       | 1       |
      | 2       | 1       |
      | 3       | 1       |
      | 4       | 2       |
      | 5       | 2       |
      | 6       | 2       |
      | 7       | 3       |
      | 8       | 3       |
      | 9       | 3       |
      | 10      | 4       |

    And the following example for 'Beer Dim':
      | beer_sk | name            | style     |
      | 1       | Invincible      | IPA       |
      | 2       | Pipewrench      | IPA       |
      | 3       | Altera          | Red       |
      | 4       | Urban Farmhouse | Farmhouse |

    Then the target 'Beer Count' should match the example:
      | name            | count |
      | Altera          | 3     |
      | Invincible      | 3     |
      | Pipewrench      | 3     |
      | Urban Farmhouse | 1     |

    And the target 'Style Count' should match the example:
      | style | count |
      | Farmhouse | 1 |
      | IPA       | 6 |
      | Red       | 3 |
