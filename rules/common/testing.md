# Testing Rules

## TDD Cycle

1. **Red** — write a failing test that defines expected behavior
2. **Green** — write minimal code to make the test pass
3. **Refactor** — clean up without changing behavior

## Test Requirements

- Every task must have corresponding tests
- Tests must be deterministic (no flaky tests)
- Test the behavior, not the implementation
- Test edge cases, not just happy path

## Test Coverage

- Target: 80%+ for new code
- Critical paths: 100%
- Don't test framework internals

## What to Test

- Happy path (expected usage)
- Error paths (what happens when things go wrong)
- Boundary conditions (empty, null, max values)
- Integration points (API contracts, database operations)

## What NOT to Test

- Framework code
- Third-party libraries
- Trivial getters/setters
- Configuration (unless validation logic)

## Test Organization

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Component interaction tests
└── fixtures/       # Test data and mocks
```

## Running Tests

```bash
# Run all tests
npm test / pytest / cargo test

# Run specific test file
npm test -- auth.test.js

# Run with coverage
npm test -- --coverage
```

## Assertions

- One logical assertion per test
- Use descriptive assertion messages
- Test one thing per test case
- Name tests to describe the scenario
