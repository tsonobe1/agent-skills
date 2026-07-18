# Fixtures and E2E

## Test Data And Fixtures

Test data should express only the facts required by the behavior being tested.

### Shared Fixtures

Do not mutate shared fixtures across tests. Each test should create its own data or derive from immutable defaults.

### Factories

Prefer factories with sensible defaults. Avoid large fixtures containing many irrelevant fields when only a small subset matters.

### Contract Accuracy

Mocks, fixtures, factories, and snapshots must remain consistent with the actual contract. When a contract changes, update fixtures, mocks, and snapshots. Outdated test doubles create false confidence.

## E2E Principles

End-to-end tests should begin from a real entry point.

Do not invent a hypothetical user flow that does not exist in code, call production APIs, or mock the core behavior under test. Prefer isolated test environments and reproducible execution. Use E2E tests to verify workflows, not implementation logic that can be verified at lower levels.

## Test Environment Isolation

Test environments should derive configuration from scenario inputs rather than hidden assumptions.

- No dependence on personal machine settings.
- No dependence on developer-specific configuration.
- Related configuration values must remain internally consistent.

Tests should remain reproducible across machines, CI environments, and operating systems.

## Mocking Boundaries

Mock only at system boundaries, such as external APIs, email services, payment providers, cloud storage, clocks and timers, and randomness.

Prefer real implementations for application code that you own. Do not mock internal collaborators merely to isolate units. When external dependencies are required, prefer dependency injection or another substitution mechanism that allows the dependency to be replaced in tests.
