---
name: tdd-review
description: Use when implementation changes add or modify tests and the test quality needs to be checked against test-case-principles. This is not a general code review.
---

# TDD Review

Use this after implementation when tests were added or changed.

This is a test-quality review, not a general code review. General code standards, architecture review, and spec conformance belong to `code-review`.

## Required Reference

Before reviewing, read this file completely:

`../test-case-principles/SKILL.md`

In the final output, include `principles_checked` with the principle names actually applied.

Every finding must name the violated principle from `test-case-principles`.

## Scope

Review only:

- added or changed tests in the current diff or task
- production code only as needed to understand the behavior contract and risk those tests claim to protect
- missing tests for behavior changed by the current diff or task

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

For changed production behavior, also ask:

1. What behavior changed?
2. Which test protects that behavior now?
3. Is the test level low enough while still giving real confidence?

## Blocking Findings

Block only when one of these applies:

- changed behavior has no corresponding test
- a bug fix has no regression test
- a test verifies implementation details instead of behavior
- a test relies on private or internal APIs
- a test oracle is tautological, untrusted, or derived from the implementation under test
- runtime boundary, persistence, rehydrate, or integration risk is untested
- one test combines multiple independent behaviors so failures are ambiguous
- a test would fail after a behavior-preserving refactor
- a fixture, mock, or snapshot is inconsistent with the real contract

Warnings are allowed for lower-risk gaps such as missing edge cases, excess setup, or test duplication that does not reduce confidence.

## Output

Start the report with the principles actually checked:

```text
principles_checked:
- <principle from test-case-principles>
- <principle from test-case-principles>
```

Then report findings in this format:

```text
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
