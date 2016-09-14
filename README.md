# Remi - Ruby Extract Map Integrate
**Warning:** This project is very much in the development stage
and all features are subject to change.  Documentation is skimpy
at best.  Test coverage is light but improving.  To get a taste
of what Remi has to offer, check out the
[sample feature](features/sample_job.feature) and [sample job](jobs/sample_job.rb).


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

The data transformation layer is built on top of
[Daru dataframe](https://github.com/v0dro/daru).  Familiarity with
Daru dataframes is essential for writing complex transformations in
Remi.

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

## Remi Jobs

A Remi job describes the data sources that will be used to collect
data, the transformations that will be performed on the data, and the
data targets that will be populated when all transformations are
complete.  With Remi, an ETL process is defined in a class that
inherits from the `Remi::Job` class.

### Hello World

A very simple "Hello World" example of a Remi job would be

````ruby
class HelloWorldJob < Remi::Job
  transform :say_hi do
    puts "Hello World"
  end
end
````

This job doesn't make use of any data subjects (data sources or data
targets), but it does define a single data transform called `:say_hi`.
The full job can be executed by calling the `#execute` method on an
instance of the `HelloWorldJob` class

````ruby
job = HelloWorldJob.new
job.execute
#=> "Hello World"
````

The transform called `say_hi` is just a method of the `HelloWorldJob`
class representing a job transform object.  Multiple transforms can be
defined in a Remi job.  To execute a specific transform we can call that transform by
name using

````ruby
job = HelloWorldJob.new
job.say_hi.execute
#=> "Hello World"
````

### A more complete example

Suppose we have a database containing data on beer sales.  It's a
normalized database where we store data on individual beers sold in a
`beer_sales_fact` table and information on the details of the beer in
a `beers_dim` table.  We'd like to extract data from both of these
sources, combine them into a single flattened table and save it as a
CSV file. This operation could be performed with the following Remi
job.  (Of course, if this were a real world problem, we'd do the join
in the database before extracting; this is a contrived example to show
how one can combine data from multiple arbitrary sources).


````ruby
class DenormalizeBeersJob < Remi::Job
  source :beer_sales_fact do
    extractor Remi::Extractor::Postgres.new(
      credentials: {
        dbname: 'my_local_db'
      },
      query: 'SELECT beer_id, sold_date, quantity FROM beer_sales_fact'
    )
    parser Remi::Parser::Postgres.new

    fields(
      {
        :beer_id  => {},
        :sold_at  => { type: :date, in_format: '%Y-%m-%d' },
        :quantity => { type: :integer }
      }
    )
  end

  source :beers_dim do
    extractor Remi::Extractor::Postgres.new(
      credentials: {
        dbname: 'my_local_db'
      },
      query: 'SELECT beer_id, name, price_per_unit FROM beers_dim'
    )
    parser Remi::Parser::Postgres.new

    fields(
      {
        :beer_id        => {},
        :name           => {},
        :price_per_unit => { type: :decimal, scale: 2 }
      }
    )
  end

  target :flat_beer_file do
    encoder Remi::Encoder::CsvFile.new
    loader Remi::Loader::LocalFile.new(
      path: 'flat_beers.csv'
    )
  end

  transform :type_enforcement do
    beer_sales_fact.enforce_types
    beers_dim.enforce_types
  end

  transform :flatten do
    flat_beer_file.df = beer_sales_fact.df.join(flat_beer_file.df, on: [:beer_id], how: :inner)

    Remi::SourceToTargetMap.apply(flat_beer_file.df) do
      map source(:quantity, :price_per_unit) .target(:total_price)
        .transform(->(row) {
          row[:quantity] * row[:price_per_unit]
        })
    end
  end
end
````

### Components of a Remi Job

A Remi job is composed of one or more of the following elements, which are described
in more detail below.  All of these elements are defined using class methods (part
of `Remi::Job`).  Each of the elements is given a name and defined in a block.

* Data Subjects - A data subject is either a data source or a data target.
  * Data Sources - A data source describes where data is extracted from.
  ````ruby
  source :my_source do
    # ... source definition
  end
  ````
  * Data Targets - A data target describes where data is loaded to.
  ````ruby
  target :my_target do
    # ... target definition
  end
  ````

* Transforms - A transform is essentially arbitrary block of of Ruby
  code, but is typically used to transform data sources into data targets.
  ````ruby
  transform :my_transform do
    # ... lots of code
  end
  ````

* Job Parameters - A job parameter is a memoized block of code
  (similar to RSpecs' `let` method) that is used to configure a job and may
  be overridden at runtime if needed.
  ````ruby
  param :my_param do
    # ... the return value of this block is memoized
  end
  ````

* Sub Transforms - Sub transforms are essentially transforms, but they are NOT
  automatically executed when the job is executed.  Instead, they must be _imported_
  in a transform.  They are meant to be reusable bits of transform code.
  ````ruby
  sub_transform :my_sub_transform do
    #... sub_transform stuff
  end
  ````

* Sub Jobs - Sub jobs are simply references to other Remi jobs that may be executed
  within the current job.
  ````ruby
  sub_job :my_sub_job { MySubJob.new }
  ````



### Execution Plan

The `DenormalizeBeersJob` example above can be executed using

````ruby
job = DenormalizeBeersJob.new
job.execute
````

Calling `#execute` on an instance of a job does the following, in this order:
1. All transforms defined in the job (via `transform :name do ... end`) are executed
   in the order they were defined in the class definition.
2. All data targets are loaded in the order they are defined in the job.

Note that data sources are not extracted until the moment the data is
needed in a transform.  If the source data is never referenced in a
transform, it is never extracted.


## Data Subjects

A _data subject_ refers to either a data source or a data target.
Either way, a data subject is associated with a data frame.  Currently
the only data frames supported are
[Daru data frames](https://github.com/v0dro/daru), but support for
other data frames may be developed in the future.  The data frame associated
with a data subject is accessed with the `#df` method and assigned with the `#df=`
method.
````ruby
  my_data_subject.df #=> Daru::DataFrame
  my_data_subject.df = Daru::DataFrame.new(...)
````

Additionally, all data subjects can be associated with a set of fields and field
metadata.  Associating a data subject with feild data allows us to develop
generic ETL routines that triggered by arbitrary metadata that may be associated
with a field.

### Sources

### Targets

### Field Metadata



## Available Data Subjects

* CSV Files
* DataFrames
* None
* Local files
* SFTP Files
* S3 Files
* Salesforce
* Postgres

## Transforms

## Sub Jobs

## Job Parameters

## Sub Transforms

## Transforming Data

When `#execute` is called on an instance of a `Remi::Job`, all transforms are executed in
the order defined in the class

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
      row[:ab] = "#{row[:a]}#{row[:b]}"
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
