# Remi Roadmap

* **0.1.0** - Basic functionality

  * [x] dataset class
  * [x] datastep method
  * [x] simple serialized dataset reader/writer
  * [x] Web-based data viewer
  * [x] unit test framework
  * [x] csv reader/writer

* **0.2.0** - Groups (public release)

  * [x] migrate to Rspec
  * [x] sort
  * [x] first/last processing
  * [ ] documentation system
  * [ ] configurable logging - user and debug
  * [ ] aggregator
  * [ ] merge
  * [ ] syntax review and refactor
  * [ ] datalib enhancements - in-memory, create/delete


* **0.3.0** - Rules

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
  * Facilitate database read/writes in Remi syntax
