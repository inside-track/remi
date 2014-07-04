# Remi - Ruby Extract Modify Integrate

**Purpose:** Remi is a Ruby-based ETL suite that is built to provide
an expressive data transformation language and facilitate the design
and implementation of business logic.

**Vision:** The vision of a functioning Remi solution includes (See
also the [fluffier long version](/doc/vision_a_story.md))

* *Core transformations* - The heart of any ETL solution is the
  ability to define, sort, merge, and aggregate data.  Remi seeks to
  provide a framework to make these core tasks simple and natural.

* *Business rule driven development support* - Borrowing from
  principles of Test Driven Development (TDD), Remi will be built to
  support Business Rule Driven Development (BRDD).  BRDD captures the
  idea that the definition of business rules, data discovery, and ETL
  coding all need to be developed in concert and continually refined.
  *All* transformation logic encoded in the ETL need to
  accessible to business users.

* *Versioned data modeling support* - In order to have an agile data
  warehouse, we need to be able to quickly build and rebuild the data
  model that is populated using ETL.  Versioning the data model is
  necessary to enable sane management of the data model changes.  Remi
  will very likely borrow heavily (if not completely) from ActiveRecord
  and Rails, which already provide solid data model versioning.

* *Data flows* - Efficiently moving data from multiple source systems
  to multiple target systems can involve a large number intermediate
  steps and complex dependencies.  Remi will provide a data flow logic
  to define and assist in the proper execution of these dependencies
  for larger projects.  It will conform to the BRDD principle that the
  transformations that are performed on the data will still be exposed
  and consumable to business users.

* *Fun* - Finally, Remi is a toolset that makes developing ETL
  solutions more fun!

**Status:** Definitely not ready for production, but ripe for play.
Right now the focus is mostly on refining the basic ETL structure in
how Remi will define, sort, merge, and aggregate data.  Once this
basic functionality has been established and demonstrated to have
performance on par with other solutions for production work, BRDD
development can begin. See the [/doc/roadmap.md](Roadmap) for a rough
sketch of plans.

I intend to follow [semantic versioning](http://semver.org/)
principles.  Of course, while we're still on major version zero, no
attempt will be made to maintain backward compatibility.


## Installation

So, this will eventually be packaged as a gem with a tool to set up
standard Remi projects, but for now we're only testing, so just

    bundle install

and go!


## Usage Overview

Data in Remi is stored in *Datasets*.  A dataset is an ordered
collection of data *records*.  Each record is a collection of variable
name/value pairs.  Typically, datasets occupy physical space on a
drive, although they might eventually be abstracted to enable support
for in-memory or in-database datasets that use a common API.  Datasets
are contained in a *Data Library* that may be a directory in a file
system, a database/schema on a database server, or just some
partitioned space in memory.  A *Datastep* is an operation on a
dataset that can involve reading, writing, modifying variable values,
sorting, merging, interleaving, or aggregating.



### Variables

Variables are objects that contain metadata describing the columns of
dataset.  They are very closely related to a hash, but include some additional
functionality.

````
# A varible can be defined on a single line use the 'new' constructor.
# Any metadata can be can be defined, but a :type is required (defaults to "string" if not given).
id = Variable.new :length => 18, :label => "SalesForce Id"

# Metadata elements can be referenced using normal accessor methods.
id[:type]
# => "string"

# Variable metadata can also be defined in a block for more complex requirements.
id = Variable.new do
  meta :type   => "string"
  meta :label  => "SalesForce Id"
  meta :length => 18
  meta :regex  => /[a-zA-Z0-9]{15,18}/
end

# This can be useful for creating other variables that are similar
account_id = Variable.new do
  like id
  meta :label => "Account Id"
end

# Metadata elements can be destructively and non-destructively dropped
another_id id.drop_meta :label, :regex
# => same as variable id, but without the :label and :regex metadata
id.drop_meta! :label, :regex
# => removed the :label and :regex metadata from id

# Or kept (note that mandatory components, like :type, do not get dropped)
another id id.keep_meta :length
#=> same as variable id, but with only the :length metadata (and mandatory :type)
id.keep_meta! :length
#=> all metadata components except :length (and mandatory :type) are removed

# keep_meta! and drop_meta! are aliased as non-bang methods in a modify! block
id.modify! do
  meta      :length => 21
  drop_meta :regex
end

````


### Libraries and datasets

Presently, Remi only supports directory-based data libraries.  A data library
is created by instantiating the **Datalib** class

````ruby
mylib = Datalib.new :directory => { :dirname => "/tmp" }
````

Referencing a dataset that is contained in a library looks just like accessing
a method

````ruby
dataset_instance = mylib.mydata
````

Calling `mylib.mydata` returns an instance of the dataset class with
the name `mydata`.

###### Proposed
I originally chose this syntax because it mimicked
SAS, which I was most familiar with.  However, I'm thinking about
refactoring this to something that may be more natural to Ruby
programmers and better capture the idea that a dataset is contained in
a library.  So in the future, datasets may be accessed more like this

````ruby
dataset_instance = mylib[:mydata]
````

The rest of the examples will follow the existing method and this
README will be updated when the code is updated.


### Creating data

The simplest currently functioning "Hello World!" example for Remi would be

````ruby
Datastep.create mylib.mydata do |ds|
  Variables.define ds do |v|
    v.create :myvariable
  end
  ds[:myvariable] = "Hello World!"
  ds.write_row
end
````

This code creates a dataset called `mydata` in the `mylib` library
(defined in the previous section).  The dataset contains a single
variable called `myvariable` with the string value "Hello World!".
Remi does not enforce variable types.  We could just have easily set
`myvariable` to the number `18` or even assigned it to be an array or
hash or any other valid Ruby object (of course, when it comes to using
the dataset to write a CSV file for export or populate a database,
assigning a variable to an array might not make much sense).  Variable
types should be enforced through the business rules.

Variables may also be associated with any amount of metadata,
represented as a hash.  You can use the metadata any way you like.
For example, you could use to trigger upcasing flagged variables.

````ruby
Datastep.create mylib.mydata do |ds|
  Variables.define ds do |v|
    v.create :var1, :upcase => true
    v.create :var2
    v.create :var3, :upcase => true
  end

  ds[:var1] = "hello"
  ds[:var2] = "to the"
  ds[:var3] = "world!"

  ds.vars do |v|
    ds[v] = ds[v].upcase if ds.vars[v][:upcase]
  end

  ds.write_row
end
````

###### Proposed

Currently the only way to define variables in a block.  It would be nice to allow
for single line definitions for simple datasteps.  For example
Definitely going to do this

````ruby
Datastep.create mylib.mydata do |ds|
  Variables.define :var1, :var2
  ds[:var1] = "Hello"
  ds[:var2] = "World!"
  ds.write_row
end
````

Also, we might want to consider allowing implicit variable creation
(although this can increase the likelihood of typos causing a
problem).  Additionally, we could support an *implicit* `write_row`
step at the end of the block, unless an explicit call to `write_row`
is made.

````ruby
Datastep.create mylib.mydata do |ds|
  ds[:myvariable] = "Hello World!"
end
````


### Viewing data

Any dataset can be browsed by calling a data view.  This uses the
Google Chart Tools to visual data (via
[GoogleVisualr](https://github.com/winston/google_visualr)).  It
launches a browser window that shows the data.  Currently it's pretty
rudimentary and data that is larger than about 1,000 records may take
a long time to load.

````ruby
Dataview.view mylib.mydata
````

###### Proposed

It would be great if we could support some kind of paging to the data view so
we wouldn't have to require the user to make sure their data is <1,000 records.
It might also be nice if we could somehow make the webpage sample random records
from a given dataset.

### Reading data

Suppose I already have a data set called `have` that exists in library
`mylib` and has a variable called `:active` that stores either "Y" or
"N".  If we wanted to read that dataset and transform it so that we
have all the same variables in `have` plus a new variable called
`:active_print` that maps "Y" and "N" to "Yes" and "No", we could do this

````ruby
  active_map = {"Y" => "Yes", "N" => "No" }
  Datastep.create mylib.want do |want|
    Variables.define want do |v|
      v.import mylib.have
      v.create :active_print
    end

    Datastep.read mylib.have do |have|
      want[:active_print] = active_map[have[:active]]
      want[:active_print] = "Undefined" if want[:active_print].nil?
      want.write_row
    end
  end
````

In the variable definition block we've used the `import` method to inherit
all variables from the `mylib.have` dataset.  The `import` method accepts
`keep` and `drop` arguments to flexibly specify the variables to be imported.
Use `keep` to include only the specified variables

````ruby
  Variables.define want do |v|
    v.import mylib.have, :keep => [:last_name, :salary]
  end
````

and use `drop` to exclude all variables except those specified

````ruby
  Variables.define want do |v|
    v.import mylib.have, :drop => [:first_name]
  end
````

If `mylib.have` had the variables
`[:last_name, :first_name, :salary]`, then the import statements above would both
give the same result.


### Importing from CSV

Remi provides an interface that makes it easy to load data from CSV
files into Remi datasets.  There are currently two ways to import: one
is with trusted headers headers and the other is with custom headers.
When using trusted headers, dataset variables are created that have
the same name as the header column headers in the CSV file.  This is
convenient for quick-and-dirty work.  But in production environments
we may not want to trust the names in the headers, and instead rely on
column position.  Below demonstrates both methods.

````ruby
csv_file_full_path = File.join(ENV['HOME'],"mydata.csv")

# Trusted headers
Datastep.create mylib.from_csv do |ds|
  CSV.datastep csv_file_full_path, header_to_vars: ds do |row|
    ds.read_row_from_csv(row)
    ds.write_row
  end
end

# Custom headers - any variables with :csv_col metadata are read from the CSV file
Datastep.create mylib.from_csv_custom do |ds|
  Variables.define ds do |v|
    v.create :first_name, :csv_col => 0
    v.create :last_name, :csv_col => 1
    v.create :salary, :csv_col => 7
  end

  CSV.datastep csv_file_full_path do |row|
    ds.read_row_from_csv(row)
    ds.write_row
  end
end
````

###### Proposed

It might be nice to add keep/drop functionality to trusted headers so that we
can optionally retain only specified variables.


### Interleaving and stacking

Assuming that two or more datasets are all sorted by the same
variables, those datasets can be interleaved resulting in a dataset
that is also sorted by the same variables

````ruby
Datastep.create mylib.mydata do |ds_out|
  Variables.define ds do |v|
    v.import mylib.ds_in1
    v.import mylib.ds_in2
  end

  Dataset.interleave mylib.ds_in1, mylib.ds_in2, by: [:var1, :var2] do |ds_interleave|
    ds_out.read_row_from ds_interleave
    ds_out.write_row
  end
end
````

Alternatively, if the `by` option is omitted, the resulting dataset just contains
datasets `ds_in1` and `ds_in2` stacked in the order given.

###### Proposed

Perhaps it would be more natural to put these operations in `Datastep.read` and it
would be obvious from context whether it's a straight read, interleave, or stack.

### Sorting

Sorting is pretty straightforward: just specify input and output datasets and
an ordered list of variables that should be used to sort:

````ruby
Datastep.sort mylib.mydata_unsorted, out: mylib.mydata_sorted, by: [:last_name,:first_name]
````

By default, Remi uses an external sort algorithm for any datasets
larger than 100,000 rows.  For these large datasets, Remi will split the dataset into
100,000 row chunks, sort each chunk in memory, and then use the interleave method
to combine all of the sorted chunks into the final dataset.  The interleave
method is currently very inefficient and needs some significant improvement, so
sorting large datasets is pretty sluggish right now.

###### Proposed

Need to implement **Ascending** and **Descending** options


### By-groups

Passing a `by` argument to `Datastep.read` provides access to methods
that indicate whether a particular row is first or last in a group.
By-groups always assume that the input data is sorted by the variables
indicated in the by-group.  This can be useful for performing complex
aggregation or in-group logic.  The simple example below shows how
by-groups can be used to count the number of records that are observed
for each value of `:var1`

````ruby
# Assumes mylib.have is sorted by :var1
Datastep.create mylib.grouped do |ds_out|
  Variables.define ds_out do |v|
    v.import mylib.have, :keep => [:var1]
    v.create :var1_count
  end

  Datastep.read mylib.have, by: [:var1] do |ds_in|
    # Initialize the counter when encountering the first record in a group
    ds_out[:var1_count] = 0 if ds_in.first(:var1)
    # Increment the counter
    ds_out[:var1_count] = ds_out[:var1_count] + 1
    # Write a record only on the last record record in the group
    ds_out.write_record if ds_in.last(:var1)
  end
end
````

### Aggregating

The example above shows how by-groups can be used to aggregate data.
By-groups are very useful in many other situations, but are a little
cumbersome for simple aggregation (especially if we don't want to go
through the trouble of sorting a dataset).  Therefore, we plan on
developing a simple aggregator syntax.

###### Proposed

````ruby
# We'll want an aggregator class that specific aggregation classes inherit

# Want the aggregator class to allow something like these functions:

# Define a function that will sum the squares of a value
class SumSquare < Aggregator
  def record(value)
    @result += value**2
  end
end

# Define a mean function
class Mean < Aggregator
  def begin_group
    @mean_sum = 0
    @n = 0
  end
  
  def record(value)
    @mean_sum += value
    @n += 1
  end

  def end_group
    @result = @mean_sum / @n
  end
end

# Run the aggregate datastep
Datastep.aggregate mylib.have, out:mylib.aggregated do |a|
  # indicate that source data is not necessarily sorted (results must fit into memory)
  a.sorted false
  # Define grouping variables
  a.by :var1
  # Define aggregation functions
  a.functions do |f|
    # :amount is a variables in the mylib.have dataset
    f.define :amount_sum_of_square, :amount, :SumSqaure
    f.define :amount_mean, :amount, :Mean
  end
  # Dataset is output at the end of the block
end
````

It would be really cool if we could build aggregator functions that could play
off of each other.  For example, calculated standard errors requires summing
the square of the difference between an individual record and the group mean.
It would be great if we could define an interface to make that kind of this simple

### Merging

###### Proposed

````ruby
Datastep.create mylib.merged do |ds_out|
  Variables.define ds_out do |v|
    v.import mylib.ds_left
    v.import mylib.ds_right
  end

  # Merge assumes ds_left and ds_right are sorted by the by variables
  Datastep.merge mylib.ds_left, mylib.ds_right, by: [:var1, :var2] do |ds_merge|
    ds_out.read_row_from ds_merge
    # Perform a left join by selecting all records in the left dataset
    ds_out.write_record if ds_merge.in(:ds_left)
  end
end
````

The above would be a way to easily perform inner, left, and right
joins.  I'm not sure at this point whether I want to support full
outer joins, because there might be complex memory issues.  On the
other hand many-to-many merges in SAS are pretty much worthless, so it
might be good to support a genuine many-to-many merge.  So we might
have to figure out a good way to get around the memory issue, or maybe
even ONLY support full outer joins that fit into memory (error if the
outer join is too big).

### Business Rules

###### Proposed

I'm still very fuzzy on the structure of the business rule definitions
and tests.  I'm not sure whether this can be just an extension of
Rspec, or if it needs to be a completely new system.  I'm expecting
something that may roughly look like this (this psuedocode needs a lot
of work)

````ruby
# The rule definition that gets applied when the ETL runs
define rule :category_map, args: [:data_record, :category_map] do
  describe rule "Use the category map to add descriptions to the category keys" do # Required examples
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

The best way to contribute would be to try it out and provide as much
feedback as possible.

If you want to develop the Remi framework then just fork, code, pull
request, repeat.  Try to follow the
[Ruby style guide](https://github.com/styleguide/ruby) and suggest
other best practices.  I'm very interested in getting other ETL
developers contribute their own perspective to the project.



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
