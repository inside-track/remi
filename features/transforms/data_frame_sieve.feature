Feature: Tests the DataFrameSieve transform

  Background:
    Given the job is 'Data Frame Sieve'
    And the job source 'Source Data'
    And the job source 'Sieve'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the source 'Sieve'
    And the target 'Target Data'


  Scenario: A slightly complicated sieve.

    Given the following example for 'Sieve':
      | level       | program | contact | group     |
      | Undergrad   | NURS    | \\nil   | intensive |
      | Undergrad   | \\nil   | true    | intensive |
      | Undergrad   | \\nil   | false   | base      |
      | Grad        | /ENG/   | true    | intensive | # regex
      | \\nil       | \\nil   | \\nil   | base      |

    And the following example for 'Source Data':
      | id | level       | program | contact |
      | 1  | Undergrad   | CHEM    | false   |
      | 2  | Undergrad   | CHEM    | true    |
      | 3  | Grad        | CHEM    | true    |
      | 4  | Undergrad   | NURS    | false   |
      | 5  | Unknown     | CHEM    | true    |
      | 6  | Grad        | ENGL    | true    |

    Then the target should match the example:
      | id | level       | program | contact | group     |
      | 1  | Undergrad   | CHEM    | false   | base      |
      | 2  | Undergrad   | CHEM    | true    | intensive |
      | 3  | Grad        | CHEM    | true    | base      |
      | 4  | Undergrad   | NURS    | false   | intensive |
      | 5  | Unknown     | CHEM    | true    | base      |
      | 6  | Grad        | ENGL    | true    | intensive |