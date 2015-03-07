# Remi Roadmap

* **0.1.0** - Basic functionality

  * [x] dataset class
  * [x] datastep method
  * [x] simple serialized dataset reader/writer
  * [x] Web-based data viewer
  * [x] unit test framework
  * [x] csv reader/writer

* **0.2.0** - Sort/Groups (quiet public release when complete)

  * [x] migrate to Rspec
  * [x] sort
  * [x] first/last processing
  * [x] documentation system
  * [x] works as a gem
  * [x] configurable logging - user and debug
  * [x] syntax review and refactor
  * [x] datalib enhancements - in-memory, create/delete
  * [ ] review of settings
  * [ ] Remi as a gem

* **0.3.0** - Merge/aggregation (slightly louder public release)
  * [ ] aggregator
  * [ ] merge
  * [ ] syntax review and refactor
  * [ ] performance benchmarking

* **0.4.0** - Business Rule Driven Development

  * Rules are methods triggered by variable or dataset metadata.  For
    example, there could be string length rule.  The rule would be
    applied to enforce the maximum length of a string.  Various
    exception handling could be invoked, e.g., hard error - stop all
    processing, soft error - replace with null or other dummy
    value/truncate and warn, warn and ignore
  * transformation rules for variables
  * transformation rules for datasets (combine/merge)

* **TBD**

  * Data flows with thread support
    * Data flows might be satisfied with state machines and resque
  * data row warnings that stop after N messages
  * Default Remi project structure (e.g. remi new mycoolproject)
  * Facilitate database read/writes in Remi syntax - or maybe just
    provide a natural interface to ActiveRecord
