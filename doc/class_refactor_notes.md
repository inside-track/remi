# Some notes on refactoring all my classes

So, I think that a lot of the classes and modules I'm building have gotten out
of hand and it's time to refactor and simplify.

* Datalib - not functional enough and might be too SASy.  I originally thought
  of these just like SAS datasets, which are simultaneously a dataset catalog
  and an interface (to files, or databases, etc).  It would probably be simplest
  to separate these out into independent functionality.

* Dataset - Seems like this could easily be split into several different objects.
  * All of the file-specific information should be split off into a datalib/interface
    object.
  * Rows have become complex enough that I think they warrant their own class.
    * By-groups would probably go here to.

  So what is a dataset?  It's the thing that ties together row-level data
  and the variables.

* Variables - I like how Variables.define sets up its own namespace for variable
  definition logic.  I'm not so sure I like the syntax though.  Could it just
  be a Remi method rather than a Variables class method.  So would this look nice
  ````ruby
  variables define ds1, ds2 do |v|
    v.create :myvar1, :type => "string"
  end

  # Or maybe I should give another shot at this
  variables define ds1, ds2 do
    create :myvar1, :type => "string"
  end

  # With the short-hand
  ````ruby
  variables define ds1 { create :myvar, :type => "string" }
  ````
  * What about making it more natural to disassociate variables from
    datasets?  So you have variable set objects that can be defined
    within a parent namespace, and imported and used (potentially
    modified?) by datasets?


  * I also need to decide whether I like the array-style syntax
    `ds[:myvar]` or object-style `ds.myvar`
    * Array-style
      * Makes a nice separation between accessing a variable in a
        dataset, vs performing some operation via a dataset method
        (e.g., `ds.first` would be ambiguous whether referencing method
        or variable).
      * Allows for variable names with spaces (even if a little
        unnatural `:"my var"`)
    * Object-style
      * Seems a little more in line with Ruby object-oriented programs
      * Could reference vars via multilevel - `ds.vars.myvar`
        * The special characeters would then have to be referenced via
          ds.vars.send(:"my var")
      * May lend itself to a cleaner separation between datasets
        and variables.
    * Mixed
      * I could separate all variables into a method of dataset and then
        access them using the array accessor like `ds.vars[:myvar]`
      * But what's the point?  I don't really have any use for ds[:myvar], so
        why not make it easier for the user?

* Datasteps - are these really class methods (via module singleton)?
  Again, does it make sense to replace `Datastep.create ds do ...` with
  `datastep create ds do ...`?
  * I sure do like that that the former gets highlighted by code editor.
  * Having `datastep create ...` would just be a module function that
    is included instead of being specified by a namespace.
  * So maybe both ideas are flawed.  Should datasteps be instance methods
    on dataset objects?  I don't know.  Ruby blogs seem to think that all
    of these things should be objects and I'm making things too "procedural".
    But it just seems to make more sense that way.
  * Datasteps could be defined as objects and given a run method.  Perhaps datasets
    should even be nestable and chainable - which could lead naturally into
    data flows.
    

* Maybe it's time to start thinking about data flows and business rules.  This might
  help refine the datastep issues I can't seem to wrap my head around.
