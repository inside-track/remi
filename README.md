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

## Getting Started

Add the gem to your Gemfile, `bundle install`, and then initialize your repository as
Remi project

    remi --init

This command will create two directories: `jobs` and `features`.  The
`jobs` directory contains an example of a Remi job that can be tested
using the BRDD spec defined in the `features` directory.  Test to make
sure this works by running

    cucumber

All of the test should pass.

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


### Transform cardinality

Within a source-to-target map block, there are a few different
possible transform cardinalities: one-to-one, many-to-one, one-to-many,
many-to-many, zero-to-one, and zero-to-many.  The lambda functions that
are supplied to `#transfrom` method must satisfy different conditions based
on cardinality.

For all of the following examples, we'll assume that a dataframe exists defined by
````ruby
  df = Remi::DataFrame::Daru.new(
    [
      ['a1','b1','c1', ['d',1]],
      ['a2','b2','c2', ['d',2]],
      ['a3','b3','c3', ['d',3]],
    ].transpose,
    order: [:a, :b, :c, :d]
  )
````

**one-to-one** - These maps expect a lambda that accepts the value of a
field as an argument and returns the result of some operation, which
is used to populate the target.

````ruby
Remi::SourceToTargetMap.apply(df) do
  map source(:a) .target(:aprime)
    .transform(->(v) { "#{v}prime" })
end

df[:aprime].to_a #=> ['a1prime', 'a2prime', 'a3prime']
````

**many-to-one** - These maps expect that the lambda accepts a row object as an argument
and returns the result of the operation, which is used to populate the target.

````ruby
Remi::SourceToTargetMap.apply(df) do
  map source(:a, :b) .target(:ab)
    .transform(->(row) { "#{row[:a]}#{row[:b]}" })
end

df[:ab].to_a #=> ['a1b1', 'a2b2', 'a3b3']
````

**zero-to-many/one-to-many/many-to-many** - These maps expect that the
lambda accepts a row object as an argument.  The row object is then
modified in place, which is used to populate the targets.  The return
value of the lambda is ignored.

````ruby
Remi::SourceToTargetMap.apply(df) do
  map source(:a, :b) .target(:aprime, :ab)
    .transform(->(row) {
      row[:aprime] = row[:a]
      row[:ab] = "#{row[:a]}#{row[:b]}" })
    })
end

df[:aprime].to_a #=> ['a1prime', 'a2prime', 'a3prime']
df[:ab].to_a #=> ['a1b1', 'a2b2', 'a3b3']
````

**zero-to-one** - These maps expect that the lambda accepts no arguments and returns the
result of some operation, which is used to populate the target.

````ruby
Remi::SourceToTargetMap.apply(df) do
  counter = 1.upto(3).to_a
  map target(:counter)
    .transform(->() { counter.pop })
end

df[:counter].to_a #=> [1, 2, 3]
````


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





## Contributing

The best way to contribute would be to try it out and provide as much
feedback as possible.

If you want to develop the Remi framework then just fork, code, pull
request, repeat.  Try to follow the
[Ruby style guide](https://github.com/styleguide/ruby) and suggest
other best practices.  I'm very interested in getting other ETL
developers contribute their own perspective to the project.
