Feature: Tests the Partitioner transform
  The partitioner keeps track of which groups it has assigned records to
  in order to keep the distribution of records into groups as precise as
  possible.


  Background:
    Given the job is 'Partitioner'
    And the job source 'Source Data'
    And the job source 'Current Population'
    And the job source 'Distribution'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the source 'Current Population'
    And the source 'Distribution'
    And the target 'Target Data'



  Scenario: Partitioning records into groups with no prior population

    Given the following example for 'Source Data':
      | id |
      |  1 |
      |  2 |
      |  3 |
      |  4 |

    And the following example for 'Distribution':
      | group | weight |
      | A     | 0.5    |
      | B     | 0.5    |
      | C     | 1      |

    Then the target has 1 records where 'group' is "A"
    Then the target has 1 records where 'group' is "B"
    Then the target has 2 records where 'group' is "C"


  Scenario: Partitioning records into groups with a prior population

    Given the following example for 'Source Data':
      | id |
      |  1 |
      |  2 |
      |  3 |
      |  4 |
      |  5 |

    And the following example for 'Distribution':
      | group | weight |
      | A     | 0.5    |
      | B     | 0.5    |
      | C     | 1      |

    And the following example for 'Current Population':
      | group | count |
      | A     | 2     |
      | B     | 1     |



    Then the target has 0 records where 'group' is "A"
    Then the target has 1 records where 'group' is "B"
    Then the target has 4 records where 'group' is "C"


#  Scenario: Remainders
#    When the target population is matched exactly, the next
#    assignment is random (and weighted by the given weights).
#    I don't know how to test this.
