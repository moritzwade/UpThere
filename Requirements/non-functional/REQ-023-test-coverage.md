---
id: REQ-023
title: Test Coverage
priority: medium
type: non-functional
status: implemented
tags: [testing, unit-tests, mocking, ci]
scenarios:
  - id: SC-023-01
    name: Run all unit tests
    given: The project is built for testing
    when: The test suite is executed
    then: All tests pass on both iOS and macOS targets
  - id: SC-023-02
    name: Mock network responses
    given: A test needs to verify API response handling
    when: MockURLProtocol is configured with a response handler
    then: The FlightService receives the mocked response instead of making a real network call
  - id: SC-023-03
    name: Test model parsing
    given: Raw OpenSky API JSON data is available
    when: The parsing logic is tested
    then: Flight objects are correctly created from the raw data
  - id: SC-023-04
    name: CI runs tests on push and PR
    given: Code is pushed to main/master or a PR is opened
    when: The GitHub Actions workflow triggers
    then: Tests are run on both iOS and macOS targets
---

# REQ-023: Test Coverage

## Description

The application uses Swift Testing framework for comprehensive unit test coverage, with a mock network layer for testing API interactions without real network calls.

## Source Files

- `UpThereTests/*Tests.swift` — Test files
- `UpThereTests/TestHelpers/TestData.swift` — Test fixtures
- `UpThereTests/MockData/MockURLProtocol.swift` — Network mocking
- `.github/workflows/tests.yml` — CI test workflow

## Acceptance Criteria

1. Tests use Swift Testing framework (`import Testing`, `@Test`, `#expect()`)
2. Test files follow naming convention: `*Tests.swift`
3. Network requests are mocked via `MockURLProtocol`
4. Test data fixtures are provided via `TestData` enum
5. Tests run on both iOS and macOS targets in CI
6. Custom `URLSession` can be injected into `FlightService` for testing

## Test Coverage by Module

| Module | Test File | Test Count | Coverage |
|--------|-----------|------------|----------|
| Flight model | `FlightTests.swift` | 12 | Parsing, conversions, formatting |
| FlightService | `FlightServiceTests.swift` | 7 | Success, errors, auth, rate limits |
| OpenSkyResponse | `OpenSkyResponseTests.swift` | 12 | JSON parsing, flight conversion |
| BoundingBox | `BoundingBoxTests.swift` | 7 | Bounds calculation, edge cases |
| Logger | `LoggerTests.swift` | 19 | Logger existence, levels, privacy, no print() |
| **Total** | | **57** | |

## Mock Infrastructure

### MockURLProtocol

| Method | Purpose |
|--------|---------|
| `configureSuccess(data:status:)` | Mock successful API response |
| `configureError(status:)` | Mock error response (401, 429, 500) |
| `configureAuthSuccess(token:)` | Mock OAuth2 token response |
| `configureNetworkError(error:)` | Mock network failure |
| `reset()` | Clear all mock configurations |

### TestData

Provides pre-built JSON fixtures for:
- Valid flight responses (single and multiple flights)
- Empty responses
- Null states responses
- Invalid JSON
- Missing required fields

## CI Configuration

| Property | Value |
|----------|-------|
| Trigger | Push to main/master, PR to main/master |
| Runner | `macos-latest` |
| Platforms | iOS (iPhone 17 simulator), macOS (arm64) |
| Code signing | Disabled (`CODE_SIGN_IDENTITY=""`) |

## Testing Conventions

- Test methods use `test*` naming (e.g., `testFetchFlightsSuccess`)
- Related tests are grouped with `// MARK:` comments
- `FlightService` tests use custom `URLSession` injection via `FlightService(config:session:)`
- Model tests verify both valid and invalid input handling

## Edge Cases

- Tests cover nil/optional field handling in Flight model
- Tests cover edge cases for BoundingBox (equator, poles, date line)
- Logger tests verify no `print()` statements exist in source files
- Tests verify both successful and error paths for all API scenarios
