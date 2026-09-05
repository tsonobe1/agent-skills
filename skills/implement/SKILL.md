---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If acceptance criteria change during implementation, state the before/after behavior and classify the delta as current scope or follow-up before editing. Do not fold an independently useful follow-up into the current change without explicit approval.

A brief acknowledgement such as `y` authorizes only the immediately named gate. Do not infer permission to commit, push, open, ready, or merge a pull request, expand scope, or clean up worktrees.

Use /tdd for testable behavior, reusing approved contracts and existing public boundaries.

Choose verification from the repository guide for the changed surface. Reuse successful evidence while the tested content and environment remain applicable. Broaden or repeat checks only for new changes, failures, or unresolved risks; run a full suite when those risks or the repository require it. Documentation-only work normally needs diff and reference checks, not product tests.

Review the changed behavior and contracts using the repository review guide and `review-standards`. Use `code-review` only for an explicitly requested strict structural audit.

If tests were added, changed, or deleted, also run /tdd-review to check them against test-case-principles.

When the input is a local tracker ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, set its `Status:` to `claimed` before implementation. After the required tests and reviews pass, and committing is authorized, set its `Status:` to `done`, then commit the implementation and the ticket's done transition together. If committing is outside the requested scope, leave the ticket claimed and report implementation-ready with commit pending. If the commit fails, report the failure and do not advance any dependent ticket; completion requires the done transition to exist in the repository. Do not mark a partial or failed implementation as done.

Obtain explicit commit approval if it has not already been given for this work; reuse applicable prior approval. Follow the user's authorized Git scope and the repository closeout guide. Commit, push, merge, and cleanup are separate actions; this skill does not extend that authorization. Preserve unrelated changes and use the repository worktree retirement procedure when one exists.
