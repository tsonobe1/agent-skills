# Boundaries and State

## Runtime Boundaries

When behavior crosses a runtime boundary, verify the value after it crosses that boundary.

- Examples include process boundaries, serialization, structured cloning, IPC, HTTP, workers, storage, and external commands.
- Data that crosses a boundary should be plain enough for that boundary.
- Do not treat an isolated unit or component test as complete evidence when the real risk is at a runtime boundary.

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

## UI Library Integration

When introducing or modifying major third-party UI components, verify that the real component can render successfully.

Examples include data grids, date pickers, virtualized lists, charts, and editors.

Prefer mounting the actual component with representative props. Avoid replacing the component with a shallow mock that bypasses the integration risk.
