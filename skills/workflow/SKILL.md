---
name: workflow
description: Shared collaboration workflow for implementing one TODO case at a time (t-wada style classical TDD). Assumes plan and TODO list are already agreed. Includes explicit review gates and repository-specific pre-commit checks.
---

# Workflow

## Objective

Execute implementation with a strict one-case TDD cadence, using explicit review gates, behavior-focused tests, and deterministic diffs.

## Outcome Contract

- Start by naming the selected TODO case, the observable outcome, success criteria, constraints, and the stop point for the current step.
- Use the one-case loop as the default path, but choose the smallest useful validation for the changed surface at each step.
- Treat review and commit gates as invariants. For investigation depth, retry count, and extra file reads, use explicit decision rules instead of open-ended iteration.
- Before closing the case, report what changed, what behavior is now guaranteed, what validation ran, and what remains unverified.

## Preconditions

- Plan and TDD TODO list are already agreed.
- We will start from an existing TODO item.

## Invocation

Use this interactive cadence only when the user explicitly requests it. Routine implementation follows the repository guide and `tdd` without the per-step human review gates. Resolve lint, format, and unused-code commands through the repository's platform-specific guide; a native-only change does not require Electron checks.

When starting work, the user says:

- `$workflow に従って、{XX} の {YY} を実装していこう`

## TDD Loop (One Case Only)

1. Pick exactly one TODO case (state the TODO id/title explicitly).
2. **Red**: add or adjust one failing test for the case.
3. Ask the user to review the test intent and failing result.
4. **Green**: implement the minimum code required to pass the test.
5. Ask the user to review the implementation.
6. **Refactor** while keeping tests green.
7. Ask the user to review the refactor.
8. **Plan Update (before commit)**:
    - Reflect the implemented behavior in the plan.
    - Mark the TODO case as completed.
    - Adjust acceptance criteria if clarified during implementation.
    - Record any design decision discovered during the case.
9. **Quality Gate (before commit)**:
    - Run the checks required by the repository guide for the changed platform and scope.
    - If a required check fails, fix within the approved scope or report the blocker.
10. **Commit the case**.
11. Move to the next TODO case.

## Guardrails

- Do not batch multiple TODO cases in one cycle.
- Each TODO must represent a single observable behavior.
- When designing or reviewing tests, use [test-case-principles](../test-case-principles/SKILL.md) for classical TDD, behavior, naming, test structure, collaborators, and contract assertions. Read its core principles and only the additional references relevant to the changed behavior.
- For this interactive workflow, group cases by normal flow (`正常系`), delegation flow (`移譲系`), and relevant preconditions. Write Japanese case names in this form, retaining English identifiers only for domain terminology:
    - XXをするYY
        - XX のとき YY となる
- Keep each step observable and explain why the change is needed.
- Prefer minimal deterministic diffs.
- Pause coding and return to discussion if disagreement appears.
- If scope changes, stop and re-align TODO/acceptance before continuing.

- The plan must be updated before every commit.
- Implementation and plan must remain consistent.
- No commit without plan alignment.

## Compatibility and fallbacks

Follow the repository's compatibility and data-preservation policy. Add fallbacks only for specified failure behavior; request clarification when that behavior is unresolved and consequential. Keep speculative compatibility work outside the change's scope.

## Review Mindset

- Treat existing implementation as potentially wrong until the specified behavior and contracts are confirmed.
- Review against behavior, specification, and contracts rather than trusting the current code shape.
- If you find or suspect an omission, ambiguous specification, bug, incorrect implementation, or simple mistake, leave a comment instead of silently accepting it.
- Surface mismatches between tests and implementation, including missing preconditions, violated postconditions, or broken invariants.

## Commit Rules

- Commit only after completing Red → Green → Refactor and passing the Quality Gate.
- Use short imperative commit messages with prefixes such as `test`, `fix`, `refactor`, `docs`, `add`.
- Keep unrelated changes out of the commit.
