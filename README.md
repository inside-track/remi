# Remi - Ruby Extract Map Integrate

**Purpose:** Remi is a Ruby-based ETL suite that is built to provide
an expressive data transformation language and facilitate the design
and implementation of business logic.

**Vision:** The vision of a functioning Remi solution includes (See
also the [fluffier long version](/doc/vision_a_story.md))

* *Business rule driven development support* - Borrowing from
  principles of Test Driven Development (TDD), Remi will be built to
  support Business Rule Driven Development (BRDD).  BRDD captures the
  idea that the definition of business rules, data discovery, and ETL
  coding all need to be developed in concert and continually refined.
  *All* transformation logic encoded in the ETL need to
  accessible to business users.

I intend to follow [semantic versioning](http://semver.org/)
principles.  Of course, while we're still on major version zero, no
attempt will be made to maintain backward compatibility.


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
