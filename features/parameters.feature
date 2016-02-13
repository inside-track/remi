Feature: Tests setting parameters

  Background:
    Given the job is 'Parameters'
    And the job source 'Source Data'
    And the job target 'Target Data'

    And the source 'Source Data'
    And the target 'Target Data'

    And the source field 'parameter_name' is set to the value "test_parameter"

  Scenario: Setting a parameter explicitly.
    Given the job parameter 'myparam' is "happypants"
    Then the target field 'myparam' is set to the value "happypants"

  Scenario: Dynamically retreiving a parameter that exists.
    Given the source field 'parameter_name' is set to the value "test_parameter"
    Then the target field 'parameter_name' is set to the value "my test parameter value"

  @fails
  Scenario: Dynamically retreiving a parameter that does not exists.
    Given the source field 'parameter_name' is set to the value "nonexisting_parameter"
    Then the target field 'parameter_name' is set to the value ""
