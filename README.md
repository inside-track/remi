# Remi - Ruby Extract Modify Integrate

**Purpose:** Remi is a Ruby-based ETL suite designed to facilitate
transformation of data in accordance with business rules and logic.
It is intended to be used primarily with structured data in the GB-TB
range (i.e, data too big to comfortably fit into memory, but not big
enough to want to go with a hadoop-like solution).

**Vision:** The core functionality of an ETL tool includes the ability
to define, sort, merge, and aggregate data.  What is often lacking in
ETL tools is how the transformations represented by ETL code relate to
business logic.  In a fast-paced agile data environment, it is nearly
impossible to maintain business-user-level documentation that is
accurate, up-to-date, and comprehensible.  The goal of Remi is to
provide all of the core functionality of a solid ETL tool while also
borrowing from Test and Behavior Driven Development methodologies to
make it possible to maintain a tight link between the actual ETL code
and the realities of rapidly changing business rules.  I'll refer to
this concept as *Business Rule Driven Development (BRDD)*.



**Status:** Right now the focus is mostly on refining the basic ETL
structure in how Remi will define, sort, merge, and aggregate data.
Once this basic functionality has been established and demonstrated to
have performance on par for production work, BRDD development can begin.

I intend to follow [semantic versioning](http://semver.org/)
principles.  But of course, while we're still on major version zero,
no attempt will be made to maintain backward compatability.


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

## Contributing

Fork, code, pull request.  Try to follow the
[Ruby style guide](https://github.com/styleguide/ruby).

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
beurocracy, politics, and apathy of working for large old fashioned
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
transformations layed out visually, and it was a snap to bring in new
data sources.  Of course, the problem with GUI-based programming is
that if the developers didn't think of including something in the
package, you're pretty much SOL.  It's also next-to-impossible to
design modular, test-driven, and flexible ETL using Kettle (if you
disagree, I'd love to see examples).  Despite our best efforts, our
Kettle code base became very difficult to manage due to a large amount
of mostly-but-not-quite-duplicated code.  Transformations would
frequently break when we fixed some seemingly-unrelated bugs.  Not to
mention the fact that the transformations we built would quikly drift
away from any business rules documentation, assuming they even
existed.

I wanted an ETL system that offered the expressiveness of a procedural
ETL solution like SAS, but also facilitated more modern coding
standards and conventions.  I had recently been exposed to Ruby
through some DevOps Chef projects I was working on and just fell in
love with it.  So, I started building out the core functionality of
Remi during those first few weeks of staying up late with Remi crying
and sleeping in 15 minute sprints.
