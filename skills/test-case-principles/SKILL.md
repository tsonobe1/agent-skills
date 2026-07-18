---
name: test-case-principles
description: Repo-independent principles for designing behavior-focused test cases. Use when drafting, reviewing, or refactoring tests; deciding what cases to write; reducing implementation-coupled tests; or applying classical TDD test design.
---

# Test Case Principles

This skill is the index for test-design principles. It is not a checklist that
requires every principle for every test. Project-specific workflow, approval,
placement, and validation commands belong in the calling skill or repo guide.

## Principle Selection

Always read [core principles](references/core.md) before designing or reviewing
a test.

Then read only the references whose risk is present in the changed behavior or
test. Keep the selected principle names in the current work state; a review
reports them as `principles_checked`.

| Risk present | Read |
| --- | --- |
| Storage, rehydrate, IPC, HTTP, serialization, workers, behavior across modules, or a major third-party UI component | [boundaries and state](references/boundaries-and-state.md) |
| Concurrency, time, randomness, polling, callbacks, streams, external processes, loading, fetching, subscriptions, or reactive updates | [deterministic async execution](references/deterministic-async.md) |
| Test level, validation choice, non-executable asset, or user-facing entry path | [coverage and validation](references/coverage-and-validation.md) |
| Fixtures, mocks, snapshots, E2E, or test-environment configuration | [fixtures and E2E](references/fixtures-and-e2e.md) |

Do not add a test or a review finding for an unselected area unless inspecting
the change establishes that its risk is present. When a risk becomes apparent,
select its reference before continuing.

## Reference Map

- [Core principles](references/core.md)
- [Boundaries and state](references/boundaries-and-state.md)
- [Deterministic async execution](references/deterministic-async.md)
- [Coverage and validation](references/coverage-and-validation.md)
- [Fixtures and E2E](references/fixtures-and-e2e.md)
