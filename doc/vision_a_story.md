
Note: Yes, the vision is quite long winded.  Mostly because at this
stage it's difficult to provide specifics, so a story will have to do
and be refined and simplified as we go.

**Vision Prelude:** ETL project development usually goes something
like this: An ETL developer, let's call him Jeff, is brought into a
room with a business data analyst, project manager, and executive
sponsor.  Jeff is given some data that the team just simply can't
function without.  Maybe that data is in the form of an Excel
spreadsheet (gasp!), or if Jeff is lucky, it's a well documented data
dictionary that comes with some 3rd-party data that the company has
purchased.  In the best of situations, the team works together to
define a set of *business rules* that must be followed in order to
correctly load the data into the existing warehouse.  However, for many
projects even this step is skipped and the ETL developer is just
expected to get the data loaded and have it load consistently every
day without error or issue.

So Jeff sits down and starts to build the ETL code.  He quickly
starts to find exceptions to the agreed-upon business rules: source
data that doesn't follow the documented formats, business scenarios
that weren't ever considered, and just damn dirty data.  For some of
these issues, Jeff takes the liberty of writing some ETL to do some of
the basic cleaning and handling of edge-cases.  If he's super-hero
diligent, some of those cleaning rules may even make it back into the
original business rule documentation, but usually the only place the
documentation lives is in the code itself.  Other cases he has to
bring back to the team, who are already getting impatient that their
data isn't ready yet.  Several meetings are called to discuss the
issues and project plans have to be revised and Gantt charts rebuilt.
The team starts to wonder what's wrong with their ETL developer, who
didn't conceive of all of the myriad of possible data quality issues
during the project planning steps before they had real data.

After several delays, the data is finally in the warehouse and nightly
data feeds are scheduled.  Everyone's happy, but they really need to
get started analyzing the data.  Two days later, some new data with
unexpected malformating is processed.  It breaks to the extent that no
data is loaded and Jeff has to rush to build in some quick fix while
the team starts freaking out over client expectations and how this
just can't happen.  No way that fix makes it into the documentation.
Two weeks later a small bug is discovered in the ETL code.  The
business rule was in the project documentation, but there was just one
small aspect of it that failed to be coded properly, maybe because the
original sample data didn't include a case like it.  Another two weeks
passes and the data analyst is again freaking out because there's this
whole sub-segment of the data that is wrong.  Turns out this is just
another bizarre business case that was never considered and no special
treatment was made to handle it in the ETL.  Fixing the issue without
breaking everything else requires some substantial refactoring and a
new rule is developed that doesn't make it into the documentation
either.

After a few months there's an ETL solution that is hanging together by
threads, prone to break when bugs are fixed, nobody trusts it, and the
only people who can answer questions about why the data behaves in a
certain way are those that can read the ETL code.

I believe there's a better way.

**Vision:** The sad state of affairs that is described above is far
too typical.  It's like the world of data integration has stayed a
decade or more behind the rest of the software development world.  I
want Remi to change that by making it easier to develop high quality,
test-driven, maintainable, and well documented ETL processes.

In the ideal vision of Remi's role, ETL development begins the same
way as described in the above scenario, with a discussion between ETL
developers and business users.  However, instead of diving in to
building out all of the minute details of the project before handling
any real data, we focus a lot of the upfront effort on data discovery.
A huge amount of data discovery goes on in the early stages of ETL
development that is often lost when the goal is just to get the known
business rules working correctly, which are inevitably incomplete or
inaccurate at the outset.  Good ETL development practice would do this
anyway, but maintaining a tight link between discovered data
structure, validations, and documentation requires a considerable
effort.

The idea behind agile ETL development is that we proceed by using
exploratory data analysis to *uncover* the business rules and the
myriad of exceptions that are inherent in the live data.  Those rules
then need to be discussed and refined with the business interests.  As
the data discovery phase proceeds, those business rules are encoded as
tests that must pass before any changes to the production ETL are
made.  Additionally, these business rules must be easily discoverable
and understood by those who understand what the data means, but don't
have a need to follow the intricacies of the the ETL code.

Much of what I'm describing above is known as Test or Behavior Driven
Development (*TDD*/*BDD*).  Remi will expand on those principles in
the area of data integration by promoting *Business Rule Driven
Development (BRDD)*.

The core functionality of an ETL tool includes the ability
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
