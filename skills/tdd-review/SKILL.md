---
name: tdd-review
description: Use when implementation changes add, modify, or delete tests and the test quality needs to be checked against test-case-principles. This is not a general code review.
---

# TDD Review

Use this after implementation when tests were added, changed, or deleted.

This is a test-quality review, not a general code review. General code standards, architecture review, and spec conformance belong to `code-review`.

## Select Principles

Read `../test-case-principles/SKILL.md` and its core principles. Select additional
references from its Principle Selection table only when the changed behavior or
test has the corresponding risk.

If the implementation recorded selected principles, begin from that set and add
only risks established by the review. Otherwise, derive the selection from the
current diff and task.

In the final output, include `principles_checked` with the principle names and
references actually applied. Every finding must name the violated principle from
the selected references.

Do not raise a finding for an unselected area unless review evidence establishes
that its risk is present; select the corresponding reference first.

## Scope

Review only:

- added, changed, or deleted tests in the current diff or task
- production code only as needed to understand the behavior contract and risk those tests claim to protect
- missing or removed tests for behavior changed or protected by the current diff or task

Do not raise production-code findings unless they explain a test-quality finding.

Do not review general code style, broad architecture, naming, comments, or non-test duplication unless it directly affects test confidence.

## Review Questions

For each added or changed test, answer:

1. What behavior does this test protect?
2. Is that behavior observable through a public interface?
3. Is the tested seam appropriate and high enough?
4. Is the oracle trustworthy and independent of the implementation?
5. Is there one independent behavior per test?
6. Would the test survive a behavior-preserving refactor?
7. Does the test cover relevant runtime boundaries, persistence, rehydrate, or integration risk?
8. If this is a bug fix, is there a regression test that would fail before the fix?
9. Can the test pass independently of suite order and without state leaked from another test?
10. Does the test name state its triggering condition and observable result, rather than making an internal method, type, helper, or implementation step the subject of the specification?

When a test uses concurrency, time, randomness, polling, or an external/runtime resource, also answer:

1. Is required event order controlled by explicit state, completion signals, or test-owned gates?
2. Does correctness depend on fixed sleeps, uncontrolled clocks, randomness, external state or resources, or scheduler timing?
3. Does every potentially non-completing wait have a boundary-appropriate deadline?
4. Does timeout output identify the wait target, expected condition, elapsed time, last observed state, and polling attempt count when applicable?
5. Is cleanup bounded to resources owned by the test, with no resource-leak path?
6. Can an automatic retry hide an initial timeout or failure?

For changed production behavior, also ask:

1. What behavior changed?
2. Which test protects that behavior now?
3. Is the test level low enough while still giving real confidence?

For each deleted test, also ask:

1. What behavior or regression did this test protect?
2. Is that behavior still protected by another test?
3. If the test was removed because behavior changed, does a replacement test protect the new behavior?

## Blocking Findings

Block only when one of these applies to the changed behavior or selected risk:

- changed behavior has no corresponding test
- a bug fix has no regression test
- a deleted test removes regression protection without an equivalent replacement
- a test verifies implementation details instead of behavior
- a test relies on private or internal APIs
- a test oracle is tautological, untrusted, or derived from the implementation under test
- runtime boundary, persistence, rehydrate, or integration risk is untested
- a test depends on suite order or an uncontrolled clock, randomness, external state or resource, or scheduler timing for correctness
- required event ordering depends on timing instead of explicit state, a completion signal, or a test-owned gate
- a callback, continuation, stream, semaphore, socket, child process, or other wait can block without a finite failure path
- a timeout omits the wait target, expected condition, elapsed time, last observed state, or polling attempt count when applicable
- cleanup can run without a bound, leak a resource, or terminate resources the test does not own
- an automatic retry allows an initial timeout or failure to be reported as passing
- one test combines multiple independent behaviors so failures are ambiguous
- a test would fail after a behavior-preserving refactor
- a fixture, mock, or snapshot is inconsistent with the real contract

Warnings are allowed for lower-risk gaps such as missing edge cases, excess setup, test duplication that does not reduce confidence, or an implementation-coupled test name. A name alone is blocking only when it reveals that the test itself verifies implementation details rather than behavior.

## Output

Start the report with the principles and references actually checked:

```text
principles_checked:
- <reference or principle from test-case-principles>
- <reference or principle from test-case-principles>
```

Then report findings in this format. Use stable `finding_id` values such as `TDD-001`; in follow-up reviews, reuse the same ID for the same unresolved issue.

```text
finding_id: TDD-001
status: blocking | warning
principle: <principle from test-case-principles>
file: <path>
line: <line or best location>
behavior_at_risk: <observable behavior>
problem: <what is wrong>
evidence: <code or test evidence>
fix: <concrete fix>
```

If there are no blocking findings, still include `principles_checked`, then say:

```text
No blocking test-quality findings.
```

Then list any warnings separately.
