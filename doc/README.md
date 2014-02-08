# Remi - Ruby Extract Modify Integrate

## Noodling notes

* Start with a test of how fast we can read data from a csv, do
  something trivial, and write out to csv.
  * Built-in Ruby CSV can input files at ~35,000 records/sec (RAD.csv)
  * Kettle can input same file at 237,000 records/sec
  * Ruby file read (no CSV parsing) can read file at 1,800,000 records/sec
  * So, if I could build serialized files that are easier to parse than
    CSV, there could be some substantial performance improvements
	

* Figure out how to sort a large csv file
  * We can use file sort (https://github.com/mopatches/file_sort_ruby_gem)
  * This is just as fast as Kettle
  

* Figure out how to merge to sorted csv files
  * file_sort does a merge

* Serialize a CSV file
  * Serialization using JSON seems to be a pretty good option.  However, some
	initial tests indicate that Kettle reads a CSV file about 4 times
	faster than the JSON created using CSV reader.
  * Try making the de-serialization process a bit faster.  Some things to try:
	* Have the created JSON use symbols instead of strings
	* Reference by column rather than name
	* Try it without gzip
  * gzip and Message Pack give performance similar to Kettle CSV
    (see serialize_performance)

* Think about a class structure for rows and fields
  * Read a csv, and create a set of fields (with user-extensible metadata)
  * Populate those fields from the csv file and define some sort of
    serialization method that could write out blocks of data to a dataset
	(that would hold the metadata in it)
  * Dataset class needs block methods to loop over rows
    * With group-by style first.dot last.dot processing and retain functionality
	  (don't do lag, but do have a retain function - perhaps retain is the default
	  for block variables)
    * Hash lookups
	* Build and process sub-datasets ?  that might be cool!

* Rule-based ETL
  * Each operation on field must be defined through a rule (that would be
  exposed to a business user)
  * Some built-in rules (copy, rename, concatenate, etc)

* Data Flows > Data Steps > Transformation Rules

* Allow for multiple output datasets and mergeable input
  
* Could the CSV reader/parser be ammended to run multithreaded?

* Start building a more formal ruby project and put all of the above together

