---
name: review-standards
description: Use when reviewing code changes that should apply personal review standards beyond repo docs and the default Matt Pocock code-review smell baseline.
---

# Review Standards

Apply these as personal standards during `code-review`, especially in the Standards axis.

Repo-specific documented standards override style and design preferences in these rules. They do not override sensitive exposure, hidden failure, contract breakage, or incomplete changed behavior. Tool-enforced formatting or lint findings should be left to the tool unless the diff shows a design or correctness problem behind them.

## Blocking Findings

Raise a blocking finding when an issue can change behavior, hide failure, break a contract, expose sensitive data, or leave incomplete code in the changed path.

- **Unsafe type escape:** `any`, unchecked casts, or ignored type errors that hide a domain contract, leak past a boundary, or make invalid states possible.
- **Fallback abuse:** placeholder values such as `unknown`, empty strings, or silent defaults that hide missing data, failed parsing, invalid state, or user-visible failure.
- **Swallowed errors:** caught errors, failed operations, or rejected async work that affect users, saved state, external side effects, or follow-up decisions without recovery, propagation, logging, or user-visible handling.
- **Untracked incomplete work:** `TODO`, `FIXME`, temporary code, or partial behavior that can ship without an issue, external blocker, and removal condition.
- **Dead changed code:** unused branches, replaced code, exported internals, or compatibility paths introduced or made unnecessary by this diff.
- **Contract drift:** changed public APIs, schemas, serialized payloads, config fields, fixtures, or callers without corresponding updates.
- **Sensitive exposure:** secrets, tokens, personal data, or private content exposed through logs, errors, snapshots, fixtures, or docs.
- **Boundary mismatch:** changed behavior crossing storage, process, network, IPC, or serialization boundaries without validation, contract updates, or tests for the boundary.

Do not block on broad unrelated cleanup. If the issue is pre-existing and not touched by the diff, report it as informational unless it directly invalidates the change.

## Warning Findings

Raise a warning, not a blocker, when the issue is lower risk or depends on judgement:

- localized `any`, casts, or ignored type errors at external library, JSON, migration, or test boundaries that are contained and justified
- fallback values that are visible, intentional, and do not hide invalid state or failed work
- shallow abstractions that add surface area but do not directly break correctness or make the change hard to maintain
- boundary-adjacent changes where the risk is plausible but no changed behavior crosses the boundary in this diff
- duplicated setup or boilerplate that does not reduce correctness confidence
- unclear names where behavior is still obvious
- missing edge cases that do not affect the changed contract
- large files or long tests without a demonstrated failure mode
- refactor opportunities outside the current change

## Design Lens

Prefer deep modules: a small interface that hides substantial behavior. Flag designs that leak internals outward, expose seams only for tests, scatter one logical change across many call sites, or create multiple shallow methods that do nearly the same thing.

Use the deletion test for abstractions: if deleting the abstraction would make the code simpler without concentrating complexity elsewhere, the abstraction is probably shallow.

## Fact Checking

Base findings on verified changed code, not memory, prior reviews, or speculation. Read the relevant file and line before raising a finding. If the evidence is missing, report the uncertainty instead of guessing.

## Finding Shape

Every finding should include:

- `finding_id`: stable within the review, using `STD-001`, `STD-002`, etc.
- `severity`: `blocking` or `warning`
- `file` and `line`
- `standard`: the rule above or repo standard violated
- `problem`: what is wrong
- `evidence`: the exact changed code or behavior
- `fix`: a concrete fix

In follow-up reviews, reuse the same `finding_id` for the same unresolved issue.

Avoid vague advice. If the fix is not clear, state the missing information instead of guessing.
