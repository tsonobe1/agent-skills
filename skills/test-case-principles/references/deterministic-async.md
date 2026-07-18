# Deterministic Async Execution

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

## Regression Protection For Re-fetch Loops

When fixing bugs related to loading, fetching, subscriptions, or reactive updates, verify stability after rerenders and state changes.

Examples include:

- rerender does not trigger duplicate API calls
- loading state transitions do not restart completed work
- callback identity changes do not cause unintended fetches

A test that only proves "it was called once" is often insufficient. Verify that it does not execute again when unrelated state changes occur.
