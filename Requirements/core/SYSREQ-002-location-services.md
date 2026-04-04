---
id: SYSREQ-002
title: Location Services
priority: high
type: feature
status: implemented
tags: [core, location, gps, permissions]
scenarios:
  - id: SC-002-01
    name: Request location permission
    given: User has not yet granted location permission
    when: The app starts and attempts to track the user
    then: A system location permission dialog is presented
  - id: SC-002-02
    name: Use GPS location when authorized
    given: User has granted location permission
    when: Location updates are started
    then: The user's current GPS location is available for flight queries
  - id: SC-002-03
    name: Fall back to default location when unauthorized
    given: User has denied or not granted location permission
    when: A flight refresh is triggered
    then: The default location (San Francisco, 37.7749, -122.4194) is used for the bounding box
  - id: SC-002-04
    name: Auto-start location on authorization grant
    given: User grants location permission after initially denying it
    when: The authorization status changes to authorized
    then: Location updates are automatically started
  - id: SC-002-05
    name: Stop location updates on tracking stop
    given: Location updates are active
    when: The user stops flight tracking (app goes to background)
    then: Location updates are stopped to conserve battery
---

# SYSREQ-002: Location Services

## Description

The application uses CoreLocation to determine the user's geographic position for flight tracking queries. Location permission is requested automatically, and a default fallback location (San Francisco) is used when the user's location is unavailable.

## Source Files

- `UpThere/Services/LocationService.swift` — CoreLocation wrapper

## Acceptance Criteria

1. LocationService is a `@MainActor` class conforming to `ObservableObject`
2. Location permission is requested using the platform-appropriate method:
   - macOS: `requestAlwaysAuthorization()`
   - iOS: `requestWhenInUseAuthorization()`
3. Location accuracy is set to `kCLLocationAccuracyHundredMeters`
4. The current location is published via `@Published var currentLocation: CLLocation?`
5. Authorization status is published via `@Published var authorizationStatus: CLAuthorizationStatus`
6. Location errors are published via `@Published var locationError: Error?`
7. Location updates start automatically when authorization is granted
8. Location updates stop when `stopUpdating()` is called
9. A static default location (San Francisco: 37.7749, -122.4194) is available as fallback

## Authorization Handling

| Platform | Authorization Method | Authorized States |
|----------|---------------------|-------------------|
| macOS | `requestAlwaysAuthorization()` | `.authorizedAlways` |
| iOS | `requestWhenInUseAuthorization()` | `.authorizedWhenInUse` or `.authorizedAlways` |

The `CLAuthorizationStatus.isAuthorized` computed property handles platform-specific checks.

## Default Location

When the user's location is unavailable (permission denied, not yet determined, or location services disabled), the app falls back to:

```
Latitude:  37.7749
Longitude: -122.4194
```

This is San Francisco, California, USA.

## Edge Cases

- Location permission is requested automatically if not granted when `startUpdating()` is called
- Authorization changes are handled via `locationManagerDidChangeAuthorization`
- Location failures are logged but do not crash the app
- The `locationError` property is cleared when a new location update succeeds
