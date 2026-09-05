---
name: workflow
description: Shared collaboration workflow for implementing one TODO case at a time (t-wada style classical TDD). Assumes plan and TODO list are already agreed. Includes explicit review gates and pre-commit quality checks (lint/format/knip).
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
    - run `lint`
    - run `format`
    - run `knip`
    - if any fail: fix minimally, keep scope constrained to the same TODO case.
10. **Commit the case**.
11. Move to the next TODO case.

## Guardrails

- Do not batch multiple TODO cases in one cycle.
- TODO must follow t-wada style, classical style TDD.
    - Behavior-first.
    - Outside-in thinking only when needed.
    - Prefer state verification over interaction verification.
    - No unnecessary mocking.
- Each TODO must represent a single observable behavior.
- Test the final result and externally observable behavior, not implementation details.
- Test cases must be written structurally.
- Classify test cases by normal flow (`正常系`), delegation flow (`移譲系`), and the relevant preconditions for the behavior under test.
- Apply design by contract in the tests and review discussion.
    - Make preconditions explicit.
    - Verify postconditions through observable outcomes.
    - Preserve invariants across the change.

  Use the following structure:
    - XXをするYY
        - XX のとき YY となる

- Test case names must be written in Japanese.
- Test names must describe behavior (condition + result), not method names.
- One test = one behavior.
- Do not test multiple branches in a single test.
- Avoid implementation detail assertions unless they are required to verify a contract-level invariant.
- Keep each step observable and explain why the change is needed.
- Prefer minimal deterministic diffs.
- Pause coding and return to discussion if disagreement appears.
- If scope changes, stop and re-align TODO/acceptance before continuing.
- Do not use English identifiers in test names unless domain terminology requires it.

- The plan must be updated before every commit.
- Implementation and plan must remain consistent.
- No commit without plan alignment.

---
- Fallbacks must be introduced only when truly necessary.
Habitual or precautionary fallbacks are strictly prohibited.
Do not introduce fallbacks that make system behavior ambiguous.
- Unnecessary fallbacks must never be added.
They are allowed only when explicitly required by the specification.
- Backward compatibility must not be considered.
The system is still in development and has not been released; therefore, impact on existing users is not a concern.
- Avoid defensive implementations created solely to preserve compatibility.
Even if a breaking change is required, it is acceptable if it results in a cleaner and more correct design.
- Prioritize structural integrity over compromise.
Do not distort the design to accommodate temporary or speculative concerns.

Intent:
- Do not accumulate defensive code merely to avoid breaking things.
- Do not introduce conditional branches based on vague “we might need this later” reasoning.
- During the pre-release phase, maximize design purity and structural clarity.

## Review Mindset

- Treat existing implementation as potentially wrong until the specified behavior and contracts are confirmed.
- Review against behavior, specification, and contracts rather than trusting the current code shape.
- If you find or suspect an omission, ambiguous specification, bug, incorrect implementation, or simple mistake, leave a comment instead of silently accepting it.
- Surface mismatches between tests and implementation, including missing preconditions, violated postconditions, or broken invariants.

## Commit Rules

- Commit only after completing Red → Green → Refactor and passing the Quality Gate.
- Use short imperative commit messages with prefixes such as `test`, `fix`, `refactor`, `docs`, `add`.
- Keep unrelated changes out of the commit.
