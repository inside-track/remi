Feature: Tests targets that are Sftp Files.

  Background:
    Given the job is 'Sftp File Target'
    And the job target 'Some File'

  Scenario: Defining the remote path.
    Given the target 'Some File'
    Then the file is uploaded to the remote path "some_file_*Today: %Y%m%d*.csv"
