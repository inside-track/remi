Feature: This is a sample feature file.
  It demonstrates some of the functionality of using Remi for BRDD.

  Background:
    Given the job is 'Sample'
    And the job source 'Sample File'
    And the job source 'Existing Contacts'
    And the job target 'Contact Updates'
    And the job target 'Contact Creates'

    And the following example record called 'existing contact':
      | Id                 | External_ID__c |
      | 003G0030H1BxH0xIIF | SAMP12345      |

    And the following example record called 'sample records to load':
      | Program | Student Id |
      | BIO     | 12345      |
      | BIO     | 0          |

    And the following example record called 'sample record to update':
      | Program | Student Id |
      | BIO     | 12345      |

    And the following example record called 'sample record to create':
      | Program | Student Id |
      | BIO     | 0          |

#####     File Specifications     #####

  Scenario: Selecting and downloading the appropriate source files

    Given the source 'Sample File'
    And files with names matching the pattern /^SampleFile_(\d+)\.txt/
    Then the file with the latest date stamp will be downloaded for processing

    Given files with names that do not match the pattern /^SampleFile_(\d+)\.txt/
    Then no files will be downloaded for processing


  Scenario: In order to be parsed and properly processed, the file must conform
    to expectations about its structure and content.

    Given the source 'Sample File'
    And the source file is delimited with a comma
    And the source file is encoded using "ISO-8859-1" format
    And the source file uses a double quote to quote embedded delimiters
    And the source file uses a preceeding double quote to escape an embedded quoting character
    And the source file uses windows or unix line endings
    And the source file contains a header row
    And the source file contains at least the following headers in no particular order:
      | header                       |
      | Student Id                   |
      | School Id                    |
      | School Name                  |
      | Program                      |
      | Last Name                    |
      | First Name                   |
      | Current Email                |
      | Mailing Address Line 1       |
      | Mailing Address Line 2       |
      | Mailing City                 |
      | Mailing State                |
      | Mailing Postal Code          |
      | Birthdate                    |
      | Applied Date                 |


#####     Record Acceptance     #####

  Scenario Outline: 'Sample File' records are rejected for non-matching programs.
    Records are rejected from all targets without error unless the
    'Program' name is included in the list of acceptable program
    names.  The examples below are not exhaustive.


    Given the source 'Sample File'
    And the target 'Contact Updates'
    And the target 'Contact Creates'
    And the example 'sample records to load' for 'Sample File'
    And the example 'existing contact' for 'Existing Contacts'

    When the source field 'Program' has the value "<Program>"
    Then the record should be <Action> without error

    Examples:
      | Program      | Action    |
      | BIO          | Retained  |
      | Fake Biology | Rejected  |
      | COMM         | Rejected  |
      | CHEM         | Retained  |


#####     Transformations common to both contact updates and creates     #####

  Scenario Outline: Populating Major__c for updates and creates.
    This scenario uses the program name mapping.  The examples below
    are not exhaustive, but are intended for demonstration and testing
    of edge cases.

    Given the source 'Sample File'
    And the target 'Contact Updates'
    And the target 'Contact Creates'
    And the example 'existing contact' for 'Existing Contacts'
    And the example 'sample records to load' for 'Sample File'

    When the source field 'Program' has the value "<Program>"
    Then the target field 'Major__c' is set to the value "<Major__c>"

    Examples:
      | Program            | Major__c  |
      | BIO                | Biology   |
      | CHEM               | Chemistry |
      | Chemistry          | Chemistry |
      | Physical Chemistry | Chemistry |
      | Microbiology       | Biology   |


#####     Transformations for creating contact records     #####

  Scenario: Fields that are present on create
    Given the target 'Contact Creates'
    And the example 'existing contact' for 'Existing Contacts'
    And the example 'sample record to create' for 'Sample File'

    Then only the following fields should be present on the target:
      | Field Name        |
      | External_ID__c    |
      | School_ID__c      |
      | School_Name__c    |
      | School__c         |
      | Major__c          |
      | FirstName         |
      | LastName          |
      | Email             |
      | MailingStreet     |
      | MailingCity       |
      | MailingState      |
      | MailingPostalCode |
      | Birthdate         |
      | Applied_Date__c   |


  Scenario: Records that are directed to Contact creates
    This example shows how to create a scenario that simultaneously references
    two sources.

    Given the source 'Sample File'
    And the source 'Existing Contacts'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'
    And the example 'existing contact' for 'Existing Contacts'

    And the source field 'Sample File: Student Id'
    And the source field 'Existing Contacts: External_ID__c' has the value "some arbitrary value"
    Then a target record is created

    When the source field 'Existing Contacts: External_ID__c' has the value in the source field 'Sample File: Student Id', prefixed with "SAMP"
    Then a target record is not created


  Scenario Outline: Fields that are copied from the 'Sample File' to 'Contact Creates'
    This example shows how a scenario can be used to specify very simple
    field mappings, like a simple copy with missing value handling.

    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'

    And the source field '<Source Field>'
    Then the target field '<Target Field>' is copied from the source field

    When the source field is blank
    Then the target field '<Target Field>' is populated with "<If Blank>"

    Examples:
      | Source Field        | Target Field      | If Blank     |
      | School Id           | School_ID__c      |              |
      | School Name         | School_Name__c    |              |
      | First Name          | FirstName         | Not Provided |
      | Last Name           | LastName          | Not Provided |
      | Mailing City        | MailingCity       |              |
      | Mailing State       | MailingState      |              |
      | Mailing Postal Code | MailingPostalCode |              |


  Scenario Outline: Date fields that are parsed and then copied from the Sample File
    to 'Contact Creates'

    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'

    And the source field '<Source Field>'
    And the source field is parsed with the date format "<Source Format>"
    Then the target field '<Target Field>' is populated from the source field using the format "<Target Format>"

    When the source field is blank
    Then the target field '<Target Field>' is populated with "<If Blank>" using the format "<Target Format>"

    Examples:
      | Source Field | Source Format | Target Field    | Target Format | If Blank       |
      | Applied Date | %m/%d/%Y      | Applied_Date__c | %Y-%m-%d      | *Today's Date* |
      | Birthdate    | %m/%d/%Y      | Birthdate       | %Y-%m-%d      |                |


  Scenario: Populating School__c
    This is an example of creating a field that is a delimited
    concatenation of two fields, where we replace blank values with "Unknowns"

    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'existing contact' for 'Existing Contacts'
    And the example 'sample records to load' for 'Sample File'

    And the source field 'School Id'
    And the source field 'School Name'
    And the target field 'School__c'
    Then the target field is a concatenation of the source fields, delimited by "-"

    When the source field 'School Id' is blank
    And the source field 'School Name' has the value "some arbitrary value"
    Then the target field is a concatenation of "Unknown" and 'School Name', delimited by "-"

    When the source field 'School Id' has the value "some arbitrary value"
    And the source field 'School Name' is blank
    Then the target field is a concatenation of 'School Id' and "Unknown", delimited by "-"


  Scenario: Populating Email
    This example shows some pre-cleaning of e-mail addresses (replacing commas with periods)

    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'

    And the source field 'Current Email'
    And the target field 'Email'

    When the source field is a valid email address
    Then the target field is copied from the source field

    When the source field is not a valid email address
    Then the target field is populated with ""

    When the source field is a valid email address
    And in the source field, periods have been used in place of commas
    Then the target field is copied from the source field, but commas have been replaced by periods


  Scenario: Populating External_ID__c

    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'

    And the source field 'Student Id'
    And the target field 'External_ID__c'
    Then the source field is prefixed with "SAMP" and loaded into the target field


  Scenario: Populating MailingStreet
    Given the source 'Sample File'
    And the target 'Contact Creates'
    And the example 'sample record to create' for 'Sample File'

    And the source field 'Mailing Address Line 1'
    And the source field 'Mailing Address Line 2'
    And the target field 'MailingStreet'
    Then the target field is a concatenation of the source fields, delimited by ", "

    When the source field 'Mailing Address Line 1' is blank
    Then the target field is populated with ""


#####     Transformations for updating contact records     #####

  Scenario: Fields that are present on update
    The business rules specify that once a student record has been
    created, only updates to the program are accepted (all other
    changes to be done in Salesforce)

    Given the target 'Contact Updates'
    And the example 'existing contact' for 'Existing Contacts'
    And the example 'sample record to create' for 'Sample File'

    Then only the following fields should be present on the target:
      | Field Name      |
      | Id              |
      | Major__c        |

  Scenario: Records that are directed to Contact updates

    Given the source 'Sample File'
    And the source 'Existing Contacts'
    And the target 'Contact Updates'
    And the example 'sample record to update' for 'Sample File'
    And the example 'existing contact' for 'Existing Contacts'

    And the source field 'Sample File:  Student Id'
    And the source field 'Existing Contacts: External_ID__c' has the value in the source field 'Sample File: Student Id', prefixed with "SAMP"
    Then a target record is created

    When the source field 'Existing Contacts: External_ID__c' has the value "some arbitrary value"
    Then a target record is not created
