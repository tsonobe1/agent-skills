---
name: tdd-review
description: Review code and tests produced through TDD. Use after implementation to perform behavior-focused, test-focused, architecture-focused, contract-focused, and regression-focused reviews. Continue review/fix cycles until no blocking findings remain.
---

# TDD Review

Review code and tests produced through TDD.

The goal is not merely to find defects.

The goal is to verify that:

- behavior is correct
- tests protect behavior
- contracts remain valid
- architecture remains maintainable
- regressions are prevented

A task is not complete while any blocking finding remains open.

---

# Review Standards

Apply all rules from:

- test-case-principles

Review both:

- production code
- test code

A test-related finding is invalid unless it explicitly identifies the violated rule from `test-case-principles`.

Examples:

- Behavior First
- One Behavior Per Test
- Runtime Boundaries
- Persistence And Rehydrate
- State Over Interaction
- Coverage And Regression Requirements

---

# Core Principles

| Principle | Criteria |
|-----------|----------|
| Fix immediately | Never defer minor issues to a future task when they can be fixed now |
| Eliminate ambiguity | Every finding must identify file, line, problem, and proposed fix |
| Fact-check | Verify actual code before raising findings |
| Practical fixes | Recommend implementable solutions, not theoretical ideals |
| Boy Scout | Leave changed or directly related code better than it was found |

---

# Parallel Reviewers

Run independent review passes from multiple perspectives.

## Behavior Reviewer

Focus on:

- public interfaces
- observable behavior
- user-visible outcomes
- behavior contracts

Questions:

- What behavior does this code provide?
- Is that behavior verified?
- Would a user observe a problem?

---

## Test Reviewer

Apply all rules from `test-case-principles`.

Focus on:

- behavior-oriented tests
- regression protection
- integration coverage
- boundary coverage
- runtime boundary verification
- persistence verification

Questions:

- What behavior does each test protect?
- Would the test survive a refactor?
- Is the test exercising public interfaces?
- Is there one behavior per test?
- Does the test actually fail if behavior breaks?

---

## Contract Reviewer

Focus on:

- public APIs
- schemas
- configuration contracts
- serialization formats
- caller compatibility

Questions:

- Has any contract changed?
- Were all callers updated?
- Were test fixtures updated?
- Were schemas updated?

---

## Architecture Reviewer

Focus on:

- deep modules
- responsibility boundaries
- abstraction quality
- duplication
- dependency direction

Questions:

- Does this abstraction reduce complexity?
- Is this a deep module or a shallow module?
- Is complexity hidden behind a simple interface?
- Is duplication justified?

---

## Regression Reviewer

Focus on:

- preserved behavior
- persistence
- migrations
- state transitions
- re-fetch loops
- workflow safety

Questions:

- Could this break existing behavior?
- Could rerenders trigger duplicate work?
- Could restore/reload behave differently?
- Is regression protection present?

---

# Scope Determination

| Situation | Verdict | Action |
|-----------|---------|--------|
| Problem introduced by this change | Blocking | REJECT |
| Code made unused by this change | Blocking | REJECT |
| Existing problem in changed or directly related code | Blocking | REJECT |
| Structural problem affecting correctness of the change | Blocking | REJECT |
| Problem in unchanged file | Non-blocking | Informational |
| Existing problem unrelated to correctness of the change | Non-blocking | Informational |
| Refactoring greatly exceeding task scope | Non-blocking | Suggestion |

---

# TDD-Specific Reject Criteria

Reject if any of the following apply.

- New behavior without tests
- Bug fix without a regression test
- Test verifies implementation details instead of behavior
- Test relies on private or internal APIs
- Multiple independent behaviors are verified in one test
- Public contract changed without corresponding test updates
- Runtime boundary changed without boundary verification
- Persistence behavior changed without restore verification
- Integration risk introduced without integration coverage
- Test would fail after a behavior-preserving refactor

---

# General Reject Criteria

Reject if any of the following apply.

- Use of `any`
- Fallback value abuse (`?? 'unknown'`)
- Explanatory comments describing what/how rather than why
- Unused code
- Swallowed errors
- TODO/FIXME without:
  - issue number
  - external blocker
  - removal condition
- Duplicated logic
- Method proliferation doing effectively the same thing
- Specific implementation leaking into generic layers
- Internal implementation exported through public APIs
- Replaced code surviving after refactoring
- Missing validation of coupled configuration fields
- Missing caller/test updates after contract changes
- Sensitive data exposed in logs, errors, or tests

---

# Warning Criteria

Not blocking.

Examples:

- Missing edge-case coverage
- Missing boundary-value coverage
- Tests coupled to implementation details
- Large or complex files
- Unclear naming
- Excessive test duplication
- TODO/FIXME with proper tracking
- `@ts-ignore` without strong justification

---

# Fact Checking

Always verify findings against actual code.

Never:

- speculate
- assume code exists
- assume code is missing
- re-raise previous findings from memory

Before raising a finding:

- read the code
- verify call sites
- verify schemas
- verify types
- verify generated outputs when relevant

Search failure is not evidence of absence.

Read the actual file and lines before concluding.

---

# Test Evaluation Checklist

For every test ask:

1. What behavior does this test protect?
2. Would this test survive an internal refactor?
3. Is the public interface exercised?
4. Could the same confidence be achieved at a lower test level?
5. Does the test fail when behavior breaks?
6. Is the violated rule traceable to test-case-principles?

---

# Writing Findings

Every finding must contain:

- finding_id
- status
- file
- line
- problem
- evidence
- proposed fix

Example:

```text
finding_id: TEST-001
status: new

file: src/auth/service.ts
line: 45

problem:
validateUser() is duplicated in three locations.

evidence:
Same logic exists at lines 45, 78, and 103.

proposed_fix:
Extract into a shared validation function located in auth/domain/validation.ts.
```

Vague feedback is prohibited.

---

# Finding Lifecycle

Valid statuses:

- new
- persists
- resolved
- reopened

Rules:

- Every blocking finding requires a finding_id.
- Reuse finding_id when the same problem persists.
- Do not reuse a finding_id for a different problem.
- Resolved findings must be explicitly listed.
- Blocking rejection requires at least one:
  - new
  - persists
  - reopened

---

# Reopen Rules

A resolved finding may be reopened only with:

1. Reproduction steps
2. Expected result
3. Actual result
4. File/line evidence

Otherwise it must remain resolved.

---

# Test File Duplication

Large tests and duplicated setup are Warning-level by default.

Reject only when duplication causes:

- flaky tests
- false positives
- false negatives
- reduced regression detection

Length alone is not sufficient.

---

# Changelog and History Files

Treat historical documents as historical records.

Do not reject because:

- current API names differ
- current schemas differ
- current behavior differs

Reject only when newly added history entries are factually incorrect.

---

# Boy Scout Rule

Leave changed or directly related code better than it was found.

Blocking:

- unused code
- unnecessary branches
- obvious duplication
- poor abstractions affecting correctness
- fixable problems in changed code

Non-blocking:

- unrelated technical debt
- large refactor opportunities
- unrelated files

---

# Review Loop

The review process is not complete until all blocking findings are resolved.

Workflow:

1. Run all parallel reviewers.
2. Merge findings.
3. Deduplicate findings.
4. Classify findings:
   - new
   - persists
   - resolved
   - reopened
5. Fix all blocking findings.
6. Re-run all reviewers.
7. Repeat until no blocking findings remain.

Never stop after the first review pass.

---

# Final Decision

## APPROVE

Approve only when:

- no blocking findings exist
- all reviewers pass
- all required tests exist
- contracts are verified
- regressions are protected

## REJECT

Reject if even one blocking finding remains.

"Approve with warnings" is prohibited.

"Approve with suggestions" is prohibited.

A task is complete only when all blocking findings are resolved.
