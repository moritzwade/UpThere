---
id: REQ-022
title: Platform Compatibility
priority: medium
type: non-functional
status: implemented
tags: [platform, ios, macos, compatibility]
scenarios:
  - id: SC-022-01
    name: Build and run on iOS
    given: The project is built for iOS
    when: The app is run on an iOS simulator or device
    then: The app functions correctly with iOS-specific behaviors
  - id: SC-022-02
    name: Build and run on macOS
    given: The project is built for macOS
    when: The app is run on macOS
    then: The app functions correctly with macOS-specific behaviors
  - id: SC-022-03
    name: Use platform-appropriate location permission
    given: The app requests location permission
    when: Running on iOS
    then: `requestWhenInUseAuthorization()` is used
  - id: SC-022-04
    name: Use platform-appropriate location permission on macOS
    given: The app requests location permission
    when: Running on macOS
    then: `requestAlwaysAuthorization()` is used
  - id: SC-022-05
    name: Exclude platform-specific files from wrong target
    given: A file named `*.ios.swift` exists
    when: The macOS target is built
    then: The file is excluded from the macOS build
---

# REQ-022: Platform Compatibility

## Description

The application supports both iOS (17.0+) and macOS (14.0+) through platform-conditional compilation and shared SwiftUI code. Platform-specific behaviors are handled using `#if os()` directives and XcodeGen file exclusions.

## Source Files

- `UpThere/Services/LocationService.swift` — Platform-conditional location handling
- `UpThere/Views/FlightMapView.swift` — Platform-conditional navigation bar style
- `project.yml` — Platform-specific file exclusions

## Acceptance Criteria

1. Minimum deployment targets: iOS 17.0+, macOS 14.0+
2. SwiftUI `@Observable` macro is used (requires iOS 17+ / macOS 14+)
3. Platform-conditional compilation is used where behavior differs
4. `*.macos.swift` files are excluded from the iOS target
5. `*.ios.swift` files are excluded from the macOS target
6. Both targets share the same core models, services, and view models

## Platform Differences

| Feature | iOS | macOS |
|---------|-----|-------|
| Location permission | `requestWhenInUseAuthorization()` | `requestAlwaysAuthorization()` |
| Authorization status access | `locationManager.authorizationStatus` | `CLLocationManager.authorizationStatus()` |
| Authorized states | `.authorizedWhenInUse` or `.authorizedAlways` | `.authorizedAlways` |
| Navigation bar style | `.inline` display mode | Default style |
| Primary navigation | `TabView` (compact) | `NavigationSplitView` (regular) |

## Platform-Conditional Code Locations

| File | Directive | Purpose |
|------|-----------|---------|
| `LocationService.swift` | `#if os(macOS)` / `#else` | Location permission and authorization status |
| `LocationService.swift` | `#if canImport(AppKit)` | AppKit import for macOS |
| `FlightMapView.swift` | `#if os(iOS)` | Navigation bar inline display mode |

## XcodeGen Exclusions

The `project.yml` configuration excludes platform-specific files:
- iOS target excludes: `*.macos.swift`
- macOS target excludes: `*.ios.swift`

## Edge Cases

- The `isAuthorized` computed property on `CLAuthorizationStatus` handles platform-specific authorized states
- The `locationManagerDidChangeAuthorization` delegate method uses platform-conditional logic for status checking
- Both platforms use the same `ContentView` with adaptive layout based on size class
