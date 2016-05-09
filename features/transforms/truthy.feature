Feature: Tests the Truthy transform

  Background:
    Given the job is 'Truthy'
    And the job source 'Source Data'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the target 'Target Data'

  Scenario Outline: Truthy without allowing nils

    Given the source field 'truthy'
    And the target field 'no_nils'

    When the source field has the value "<source>"
    Then the target field is set to the value "<target>"

  Examples:
    | source   | target |
    | True     | true   |
    | t        | true   |
    | yEs      | true   |
    | Y        | true   |
    | 1        | true   |
    | Yessir   | false  |
    | anything | false  |



  Scenario Outline: Truthy allowing nils

    Given the source field 'truthy'
    And the target field 'allow_nils'

    When the source field has the value "<source>"
    Then the target field is set to the value "<target>"

  Examples:
    | source   | target |
    | True     | true   |
    | t        | true   |
    | yEs      | true   |
    | Y        | true   |
    | 1        | true   |
    | Yessir   |        |
    | anything |        |
    | FALSE    | false  |
    | f        | false  |
    | no       | false  |
    | N        | false  |
    | 0        | false  |
