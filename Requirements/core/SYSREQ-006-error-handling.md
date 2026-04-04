---
id: SYSREQ-006
title: Error Handling
priority: medium
type: feature
status: implemented
tags: [core, errors, resilience, ux]
scenarios:
  - id: SC-006-01
    name: Display network error on map
    given: A flight fetch fails due to a network error
    when: The error occurs
    then: An error banner is displayed on the map view with the error message
  - id: SC-006-02
    name: Display rate limit error
    given: The OpenSky API returns a 429 rate limit response
    when: The error occurs
    then: An error banner is displayed indicating the rate limit was exceeded
  - id: SC-006-03
    name: Display authentication error
    given: Invalid OpenSky credentials are configured
    when: A flight fetch is attempted
    then: An error banner is displayed indicating invalid credentials
  - id: SC-006-04
    name: Show empty state when no flights
    given: No flights are detected in the current area
    when: The flight list is displayed
    then: An empty state view with "No Flights" message is shown
  - id: SC-006-05
    name: Clear error on next successful refresh
    given: An error message is currently displayed
    when: A subsequent flight refresh succeeds
    then: The error message is cleared and the banner is hidden
---

# SYSREQ-006: Error Handling

## Description

The application handles errors gracefully at all layers: network failures, API errors, authentication issues, and empty data states. Errors are communicated to the user through UI feedback and logged for debugging.

## Source Files

- `UpThere/ViewModels/UpThereViewModel.swift` — Error state management
- `UpThere/Views/FlightMapView.swift` — Error banner UI
- `UpThere/Views/FlightListView.swift` — Empty state UI
- `UpThere/Models/OpenSkyResponse.swift` — `OpenSkyError` enum
- `UpThere/Services/FlightService.swift` — Error classification and logging

## Acceptance Criteria

1. All errors are captured in `viewModel.errorMessage: String?`
2. The error banner is displayed on the map view when `errorMessage` is non-nil
3. The error banner uses an orange background with an exclamation mark triangle icon
4. The `errorMessage` is cleared at the start of each refresh attempt
5. Empty flight lists show a dedicated empty state view
6. `OpenSkyError` provides human-readable `errorDescription` for all cases
7. All errors are logged at the appropriate level (warning or error)

## Error Types

| Error | HTTP Status | Description | User Message |
|-------|-------------|-------------|--------------|
| `invalidResponse` | Non-200/401/429 | Unexpected API response | "Invalid response from OpenSky API" |
| `networkError(Error)` | N/A | Network connectivity failure | "Network error: <underlying error>" |
| `unauthorized` | 401 | Invalid or missing credentials | "Invalid OpenSky credentials" |
| `rateLimited` | 429 | API rate limit exceeded | "OpenSky rate limit exceeded" |

## UI Elements

| View | Element | Condition |
|------|---------|-----------|
| FlightMapView | Error banner | `viewModel.errorMessage != nil` |
| FlightListView | Empty state overlay | `viewModel.flights.isEmpty && !viewModel.isLoading` |

## Error Banner

The error banner appears at the bottom of the map view:
- Orange background with 0.9 opacity
- White text
- Exclamation mark triangle icon
- Rounded corners (10pt radius)

## Empty State

The empty state appears centered in the flight list:
- Large airplane icon (60pt, secondary color)
- "No Flights" title (title2, semibold)
- "No flights detected in your area" subtitle (caption, secondary color)

## Edge Cases

- Error is cleared before each refresh attempt regardless of outcome
- Previous flight data remains visible when an error occurs (only the error banner is added)
- Network errors include the underlying error's localized description
- Auth errors during token refresh are logged but do not crash the app
