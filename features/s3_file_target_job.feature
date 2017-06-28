Feature: Tests targets that are S3 Files.

  Background:
    Given the job is 'S3 File Target'
    And the job target 'Some File'

  Scenario: Defining the remote path.
    Given the target 'Some File'
    Then the file is uploaded to the S3 bucket "the-big-one"
    And the file is uploaded to the remote path "some_file_*Today: %Y%m%d*.csv"
