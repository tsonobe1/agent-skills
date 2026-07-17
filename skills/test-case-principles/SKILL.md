---
name: test-case-principles
description: Repo-independent principles for designing behavior-focused test cases. Use when drafting, reviewing, or refactoring tests; deciding what cases to write; reducing implementation-coupled tests; or applying classical TDD test design.
---

# Test Case Principles

Use these rules when designing test cases. They are repo-independent principles; project-specific workflow, approval, placement, and gate rules belong in the calling skill or repo guide.

## Classical TDD

Use classical-school TDD.

- Prefer real collaborators and real code paths.
- Use mocks as little as possible.
- Mock only when the real collaborator would make the test slow, flaky, unsafe, or outside the behavior under test.
- Do not mock the behavior you are trying to trust.

## Behavior First

Tests should verify behavior visible from outside the implementation.

- Test observable results, not implementation details.
- Do not make DOM nodes, selectors, internal types, repository APIs, method calls, or helper names the subject of the test.
- Describe what the user or caller does, then what screen state, saved state, output, or operation result changes.
- Selectors may be used as test implementation tools, but they should not define the specification.

## One Behavior Per Test

Each test should protect one independent behavior.

- 1 test = 1 behavior.
- Do not use one test to guarantee multiple specifications at once.
- Do not combine multiple specifications into one broad test.
- Split cases when a failure would not clearly identify which behavior broke.
- Prefer a small set of high-signal behavior tests over many implementation-shape tests.

## Condition Plus Result Names

Name tests as a condition plus an observable result.

- Good: `when a deleted reference is selected, only that reference link can be removed`
- Good: `when multiple deleted references exist on the same item, the count matches the rendered list`
- Avoid method-name paraphrases and internal process names.

## Coverage Categories

Consider these categories before deciding the test list.

- Happy path: normal user or caller actions produce the expected result.
- Error path: invalid state, missing target, failed input, or deleted data is handled as specified.
- Boundary condition: zero, one, many; empty value, minimum, maximum; mixed valid and invalid data; before and after reload, undo, or redo.
- Preconditions: only test setup requirements when they are observable or part of the behavior contract.
- Contract and invariant: rules that must stay true after operations, such as counts matching rendered items, saved state matching visible state, or unrelated data staying unchanged.

## Runtime Boundaries

When behavior crosses a runtime boundary, verify the value after it crosses that boundary.

- Examples include process boundaries, serialization, structured cloning, IPC, HTTP, workers, storage, and external commands.
- Data that crosses a boundary should be plain enough for that boundary.
- Do not treat an isolated unit or component test as complete evidence when the real risk is at a runtime boundary.

## Deterministic Execution And Bounded Waiting

Determinism is per-test independence, not a fixed suite order. Each test must control the events that decide its result and return every wait through a finite, diagnosable failure path.

### Execution Independence

- Each test must pass independently of suite order and create or reset the state it relies on.
- Order events inside the test with explicit observable state, completion signals, or gates owned by the test.
- Control or isolate clocks, randomness, and external resources whenever they can affect correctness.
- Make scheduler timing irrelevant by synchronizing on an observable condition. A fixed sleep or assumed scheduler timing is not evidence that the condition occurred.

### Finite Failure Paths

- Every wait that may never complete must have a finite deadline. This includes callbacks, continuations, streams, semaphores, sockets, and child processes.
- Choose a finite deadline from the processing boundary and expected duration; there is no universal duration for every test.
- On timeout, report the wait target, expected condition, elapsed time, last observed state, and, for polling, the attempt count.
- Cleanup must be bounded and limited to resources owned by the test.
- Surface a timeout or failure as a test failure. An automatic retry must not convert a failed attempt into a passing result.

## Persistence And Rehydrate

When behavior depends on saved state, test the saved and restored behavior.

- Verify the state shape that is saved when it is part of the contract.
- Verify that reloading or reconstructing the app restores the expected observable state.
- Verify payloads after storage, IPC, or serialization boundaries when those boundaries are part of the risk.

## Data Flow Integration Requirements

Unit tests are not sufficient when risk exists in the interaction between modules.

Integration tests are required when:

- A behavior crosses three or more modules.
- A new state joins an existing workflow.
- A new option or parameter propagates through a call chain.
- The primary risk is in the interaction between modules rather than inside one module.

Do not assume that passing unit tests provide sufficient evidence when the failure mode exists in the integration path.

## State Over Interaction

Prefer state verification over interaction verification.

- Prefer "the resulting state/output/display changed correctly" over "this function was called".
- Use interaction verification only when the interaction itself is the externally meaningful contract.
- Avoid mocks that replace the behavior you are trying to trust.

## Trustworthy Oracles

Do not write comparison tests against an untrusted source of truth.

- Do not assume old fixtures, current implementation output, or historical snapshots are correct.
- If the oracle is questionable, confirm it from the specification, current user-visible behavior, current code contract, or direct measurement before using it.

## Existing Tests

Before changing tests, classify existing cases.

- Keep: still protects current behavior.
- Update: name, setup, expectation, or responsibility boundary needs to change.
- Delete: protects incorrect, duplicated, or retired behavior and should be removed.
- No longer needed: falls outside the accepted behavior contract or depends on an oracle now known to be wrong.

When removing or making a test unnecessary, be able to explain which behavior contract no longer requires it.

## Coverage And Regression Requirements

Every behavior change must have a corresponding test. Every bug fix must have a regression test.

### Required Coverage

The following are mandatory:

- New behavior requires tests.
- Bug fixes require regression tests that fail before the fix and pass after it.
- Behavior changes require updating existing tests to match the new contract.
- Type checking and build validation must pass.

Absence of required tests should be treated as a blocking issue.

### Coverage Prioritization

Prioritize testing effort according to risk.

High priority:

- Business logic
- State transitions
- Workflow orchestration
- Data integrity rules

Medium priority:

- Error handling
- Boundary conditions
- Invalid input handling

Low priority:

- Simple CRUD behavior
- Thin pass-through logic

Boundary and edge-case coverage is encouraged but should not replace coverage of core behavior.

## Test Pyramid Guidance

Prefer the lowest test level that can confidently verify the behavior.

Order of preference:

1. Unit tests
2. Integration tests
3. End-to-end tests

Do not use an E2E test when the behavior can be verified with sufficient confidence at a lower level.

Use higher-level tests when the risk exists in:

- system integration
- runtime boundaries
- user workflows

## Test Structure

Use a clear Arrange-Act-Assert structure (also known as Given-When-Then).

A test should clearly communicate:

- what was set up
- what action occurred
- what behavior was observed

## Non-Executable Assets

Tests should not lock down content that is not part of the executable behavior contract.

Avoid tests that verify:

- README text
- Markdown document content
- Section headings
- Chapter structure
- Documentation wording
- Presence of documentation files that may legitimately be reorganized

Documentation changes should normally be validated through:

- review
- linting
- link checking
- executable examples

Tests are appropriate only when the artifact participates in a runtime contract or machine-readable interface.

Examples:

- schemas
- generated outputs
- configuration contracts
- executable CLI examples

## Test Data And Fixtures

Test data should express only the facts required by the behavior being tested.

### Shared Fixtures

Do not mutate shared fixtures across tests.

Each test should create its own data or derive from immutable defaults.

### Factories

Prefer factories with sensible defaults.

Avoid large fixtures containing many irrelevant fields when only a small subset matters.

### Contract Accuracy

Mocks, fixtures, factories, and snapshots must remain consistent with the actual contract.

When a contract changes:

- fixtures should be updated
- mocks should be updated
- snapshots should be updated

Outdated test doubles create false confidence.

## Entry Point Verification

When introducing or modifying user-facing functionality, verify that users can actually reach it.

Examples of valid entry points:

- routes
- navigation
- menus
- buttons
- links
- commands
- external callbacks

A screen rendering test alone is insufficient evidence if the user cannot reach that screen through the real entry path.

## UI Library Integration

When introducing or modifying major third-party UI components, verify that the real component can render successfully.

Examples:

- data grids
- date pickers
- virtualized lists
- charts
- editors

Prefer mounting the actual component with representative props.

Avoid replacing the component with a shallow mock that bypasses the integration risk.

## Regression Protection For Re-fetch Loops

When fixing bugs related to loading, fetching, subscriptions, or reactive updates, verify stability after rerenders and state changes.

Examples:

- rerender does not trigger duplicate API calls
- loading state transitions do not restart completed work
- callback identity changes do not cause unintended fetches

A test that only proves "it was called once" is often insufficient.

Verify that it does not execute again when unrelated state changes occur.

## E2E Principles

End-to-end tests should begin from a real entry point.

Do not:

- invent a hypothetical user flow that does not exist in code
- call production APIs
- mock the core behavior under test

Prefer:

- isolated test environments
- reproducible execution

Use E2E tests to verify workflows, not implementation logic that can be verified at lower levels.

## Test Environment Isolation

Test environments should derive configuration from scenario inputs rather than hidden assumptions.

Requirements:

- No dependence on personal machine settings.
- No dependence on developer-specific configuration.
- Related configuration values must remain internally consistent.

Tests should remain reproducible across machines, CI environments, and operating systems.

## Mocking Boundaries

Mock only at system boundaries.

Examples:

- external APIs
- email services
- payment providers
- cloud storage
- clocks and timers
- randomness

Prefer real implementations for application code that you own.

Do not mock internal collaborators merely to isolate units.

When external dependencies are required, prefer dependency injection or other substitution mechanisms that allow the dependency to be replaced in tests.
