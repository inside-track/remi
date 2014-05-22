# Remi - Ruby Extract Modify Integrate

**Purpose:** Remi is a Ruby-based ETL suite that is built to provide
an expressive data transformation language and facilitate the design,
definition, and implementation business rules and logic.

**Vision:** [fluffy version](/doc/vision_a_story.md).  In our vision
of Remi, we see

The vision of a functioning Remi solution includes

* Core transformation logic
* Business rule driven development support
* Versioned data modeling support
* Data flows to support modularized control of many-layered projects
* Leverage the power of Ruby
* Finally, Remi is a toolset that makes developing ETL solutions more
  fun!


**Status:** Right now the focus is mostly on refining the basic ETL
structure in how Remi will define, sort, merge, and aggregate data.
Once this basic functionality has been established and demonstrated to
have performance on par for production work, BRDD development can
begin. See the [/doc/roadmap.md](Roadmap) for a rough sketch of plans.

I intend to follow [semantic versioning](http://semver.org/)
principles.  But of course, while we're still on major version zero,
no attempt will be made to maintain backward compatibility.


## Installation

So, this will eventually be packaged as a gem with a tool to set up
standard Remi projects, but for now we're only testing, so just

    bundle install

and go!

## Usage Overview

Data in Remi is stored in *Datasets*.  A dataset is an ordered
collection of values of data organized by variables.

Typically, datasets occupy
physical space on a drive, although they might eventually be
abstracted to enable support for in-memory or in-database datasets
that use a common API.  *Datasets* are contained in a *Data Library*
that may be a directory in a file system, a database/schema on a
database server, or just some partitioned space in memory.  A
*Datastep* is an operation on a *Dataset* that involves transforming.

### Libraries

probably should be doing libname[:dataset] to be more ruby-natural

### Creating data

### Viewing data

### Reading data

### Importing from CSV

### Sorting

### Merging

### Aggregating

### Business Rules

I'm still very fuzzy on the structure of the business rule definitions
and tests.  I'm not sure whether this can be just an extension of
Rspec, or if it needs to be a completely new system.  I'm expecting
something that may roughly look like this (this psuedocode needs a lot
of work)

````ruby
# The rule definition that gets applied when the ETL runs
define rule :category_map, args: [:data_record, :category_map] do
  describe rule "Use the category map to add descriptions to the cateogry keys" do # Required examples
    input_record = ['A',50]
    category_map = { 'A' => 'Category Alpha' }
    expected_output_record = ['Category Alpha',50]
  end
    
    #... code that does the mapping ...
end

# A test that the rule definition gives the expected result
expect { apply_rule(:category_map).to input_record, category_map }.to eq expected_output_record
````

## Contributing

Fork, code, pull request, repeat.  Try to follow the
[Ruby style guide](https://github.com/styleguide/ruby) and suggest
other best practices.  I'm very interested in getting other ETL developers
contribute their own perspective to the project.

## About

Remi was conceived during the paternity time I took off work to care
for my son during his first week of life, whose name is not
coincidentally also Remi.  While I suppose a better father would have
had nothing to do other than dote and oogle over their new baby, the
fact of the matter is that newborns are just plain boring.  Other than
making sure they're snuggled and their mothers get enough sleep,
there's not much to do but stare and them and think.  So I found
myself daydreaming a lot about my job and what I can do to fix my
least favorite parts of it.

I started doing ETL work about five years prior to Remi when I worked
in the analytics unit of a health insurance company.  We used a
dinosaur of a language called SAS to transform claim data into
business-reportable cubes.  Despite it being a language that was
clearly showing its age, it was still fairly expressive and
facilitated writing fast and complex ETL code.  I ended up getting
pretty good at SAS, and the warehouse I helped build supported the
company's core analytics efforts.  But then I got fed up with the
bureaucracy, politics, and apathy of working for large old fashioned
company and decided to join a startup that prided themselves on
cloud-based open source technology.

At first I felt very lost without SAS, but with the cost of a license
being roughly $5,000/year, all of my SAS-specific knowledge was pretty
worthless.  It was hard to find alternative open source tools that
made it quick and easy to visualize data for the purposes of data
transformation and integration.  Sure, there's R, but while learning
it, I very quickly started running into the memory limits and the
community packages to work around the issue felt very cumbersome.

My new company had chosen to go with Pentaho's Kettle for their ETL
solution.  At first, I rather liked it.  It was nice to see data
transformations laid out visually, and it was a snap to bring in new
data sources.  Of course, the problem with GUI-based programming is
that if the developers didn't think of including something in the
package, you're pretty much SOL.  It's also next-to-impossible to
design modular, test-driven, and flexible ETL using Kettle (if you
disagree, I'd love to see examples).  Despite our best efforts, our
Kettle code base became very difficult to manage due to a large amount
of mostly-but-not-quite-duplicated code.  Transformations would
frequently break when we fixed some seemingly-unrelated bugs.  Not to
mention the fact that the transformations we built would quickly drift
away from any business rules documentation, assuming they even
existed.

I wanted an ETL system that offered the expressiveness of a procedural
ETL solution like SAS, but also facilitated more modern coding
standards and conventions.  I had recently been exposed to Ruby
through some DevOps Chef projects and just though it would be great
fun to build a significant project with it.  So, I started building
out the core functionality of Remi during those first few weeks of
staying up late with Remi crying and sleeping in 15 minute sprints.
