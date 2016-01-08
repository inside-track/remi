# Remi - Ruby Extract Map Integrate

**Purpose:** Remi is a Ruby-based ETL package that provides an
expressive data transformation language and facilitates the
implementation and validation of non-technical business logic.

Borrowing from principles of test/behavior-driven development
(TDD/BDD), Remi is a system that supports business-rule-driven
development (BRDD).  BRDD captures the idea that the rules that
describe data transformations should both (1) be accessible to
non-technical business users and (2) be strictly enforced in the logic
that executes those transformations.  Remi is a Ruby application
that allows a developer to write data transformation logic and have
that logic validated according to business rule documentation.


Remi will follow [semantic versioning](http://semver.org/) principles.
Of course, while we're still on major version zero, little effort will
be made to maintain backward compatibility.

## Transforming Data

TODO:

Describe Daru foundation

Examples setting up a job class with
* csv source
* sf source
* dataframe intermediate target
* csv target
* parameters
* maps

## Business Rules

TODO: Description of writing Business Rules.

### Conventions to follow when writing features

* Sources, targets, examples, field names enclosed in single quotes - `'field name'`
* Field values enclosed in double quotes - `"field value"`
* Special functions enclosed in stars - `*function*`
* Example values encolsed in angular brackets - `<example>`

Write whatever in scenario and feature descriptions

### Common step library


`Given the job is 'My Cool Job'`
`Given the job source 'Client File'`
`Given the job source 'Salesforce Extract'
`Given the job target 'Salesforce Contact'`

    Given the following example record called 'my killer example record':
      | Id   | Name                |
      | 1234 | OneTwoThreeFour     |

... etc ...

## Business Rule Validation

TODO: Description of how to write Business Rule validations.


## Installation

So, this will eventually be packaged as a gem with a tool to set up
standard Remi projects, but for now we're only testing, so just

    bundle install

and go!



## Contributing

The best way to contribute would be to try it out and provide as much
feedback as possible.

If you want to develop the Remi framework then just fork, code, pull
request, repeat.  Try to follow the
[Ruby style guide](https://github.com/styleguide/ruby) and suggest
other best practices.  I'm very interested in getting other ETL
developers contribute their own perspective to the project.
