# Coverage and Validation

## Test Pyramid Guidance

Prefer the lowest test level that can confidently verify the behavior.

1. Unit tests
2. Integration tests
3. End-to-end tests

Do not use an E2E test when the behavior can be verified with sufficient confidence at a lower level. Use higher-level tests when the risk exists in system integration, runtime boundaries, or user workflows.

## Non-Executable Assets

Tests should not lock down content that is not part of the executable behavior contract.

Avoid tests that verify README text, Markdown document content, section headings, chapter structure, documentation wording, or the presence of documentation files that may legitimately be reorganized.

Validate documentation changes through review, linting, link checking, or executable examples. Tests are appropriate when an artifact participates in a runtime contract or machine-readable interface, such as schemas, generated outputs, configuration contracts, or executable CLI examples.

## Entry Point Verification

When introducing or modifying user-facing functionality, verify that users can actually reach it.

Examples of valid entry points include routes, navigation, menus, buttons, links, commands, and external callbacks. A screen rendering test alone is insufficient evidence if the user cannot reach that screen through the real entry path.
