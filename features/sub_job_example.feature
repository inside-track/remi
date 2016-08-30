Feature: This is a job that demonstrates how to use Remi subjobs

  Background:
    Given the job is 'Sub Job Example'
    And the job target 'Just Beers'
    And the job target 'Zombified Beers'

  Scenario: Sub jobs can be used to extract data

    Given the target 'Just Beers'

    Then the target should match the example:
      | Brewer  | Style |
      | Baerlic | IPA   |
      | Ex Novo | Red   |

  Scenario: Sub jobs can be used to transform source data

    Given the target 'Zombified Beers'

    Then the target should match the example:
      | Brewer         | Style      |
      | Zombie Baerlic | Zombie IPA |
      | Zombie Ex Novo | Zombie Red |
