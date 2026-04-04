---
id: REQ-021
title: Logging
priority: medium
type: non-functional
status: implemented
tags: [logging, debugging, os-log, observability]
scenarios:
  - id: SC-021-01
    name: Log flight fetch requests
    given: A flight fetch is initiated
    when: The request URL is built
    then: A debug log is written with the full URL
  - id: SC-021-02
    name: Log successful flight fetch
    given: A flight fetch completes successfully
    when: The response is parsed
    then: An info log is written with the number of flights fetched
  - id: SC-021-03
    name: Log location updates
    given: Location services are active
    when: A new location is received
    then: A debug log is written with the latitude and longitude
  - id: SC-021-04
    name: Log errors
    given: An error occurs in any service
    when: The error is caught
    then: An error-level log is written with the error description
  - id: SC-021-05
    name: No print statements in production code
    given: The codebase is reviewed
    when: Source files in Services and ViewModels are scanned
    then: No `print()` statements are found
---

# REQ-021: Logging

## Description

The application uses Apple's `os.Logger` framework via a centralized `AppLogger` enum for structured, privacy-aware logging. All log statements use appropriate log levels and privacy annotations.

## Source Files

- `UpThere/Services/Logger.swift` — Centralized `AppLogger` enum

## Acceptance Criteria

1. All logging goes through the `AppLogger` enum — no `print()` statements in production code
2. All loggers use subsystem `com.moritzwade.upthere`
3. Three logger categories exist: `FlightService`, `LocationService`, `ViewModel`
4. Privacy levels are used correctly: `.public` for non-sensitive values, default (private) for sensitive data
5. Appropriate log levels are used per the log level guide

## Logger Categories

| Logger | Category | Purpose |
|--------|----------|---------|
| `AppLogger.flightService` | `FlightService` | OpenSky API requests, responses, auth, errors |
| `AppLogger.locationService` | `LocationService` | Location updates, authorization changes, errors |
| `AppLogger.viewModel` | `ViewModel` | Tracking lifecycle, refresh events, errors |

## Log Level Guide

| Level | Use Case | Examples |
|-------|----------|----------|
| `debug` | Verbose operational details | Request URLs, coordinates, flight counts, token expiry |
| `info` | Key business events | Tracking start/stop, flights fetched, auth granted |
| `warning` | Recoverable issues | Token refresh, rate limits, missing location, unauthorized |
| `error` | Failures | Network errors, auth failures, location failures, parsing errors |

## Privacy Rules

| Data Type | Privacy | Examples |
|-----------|---------|----------|
| Non-sensitive | `.public` | Flight counts, status codes, coordinates, URLs |
| Sensitive | default (private) | Auth tokens, credentials, auth details |

## Usage Pattern

```swift
AppLogger.flightService.debug("Fetching flights: \(url.absoluteString, privacy: .public)")
AppLogger.viewModel.info("Starting flight tracking")
AppLogger.locationService.error("Location failed", error: someError)
```

## Edge Cases

- `print()` statements are prohibited in FlightService, LocationService, and ViewModel source files
- Error messages in logs use `.public` privacy for the error description (safe for debugging)
- Auth error responses from the API are logged without exposing credentials
- Token expiry time is logged with the remaining seconds (public, non-sensitive)
