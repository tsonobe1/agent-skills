---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work.

If tests were added, changed, or deleted, also run /tdd-review to check them against test-case-principles.

When the input is a local tracker ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, set its `Status:` to `claimed` before implementation. After the tests and reviews pass, set its `Status:` to `done`, then commit the implementation and the ticket's done transition together. If the commit fails, report the failure and do not advance any dependent ticket; completion requires the done transition to exist in the repository. Do not mark a partial or failed implementation as done.

For other inputs, commit your work to the current branch.
