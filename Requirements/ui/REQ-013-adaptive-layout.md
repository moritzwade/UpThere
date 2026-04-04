---
id: REQ-013
title: Adaptive Layout
priority: medium
type: feature
status: implemented
tags: [ui, responsive, ipad, iphone, navigation]
scenarios:
  - id: SC-013-01
    name: Show split view on iPad
    given: App is running on iPad or in a regular size class environment
    when: The app launches
    then: A NavigationSplitView is shown with the flight list in the sidebar and the map as the detail pane
  - id: SC-013-02
    name: Show tab view on iPhone
    given: App is running on iPhone or in a compact size class environment
    when: The app launches
    then: A TabView is shown with Map and Flights tabs
  - id: SC-013-03
    name: Present flight detail sheet on any layout
    given: A flight is selected from either the split view or tab view
    when: The flight is tapped
    then: The flight detail sheet is presented as a modal overlay
  - id: SC-013-04
    name: Start tracking on appear
    given: The app's main view appears
    when: ContentView is displayed
    then: Flight tracking is started (location + auto-refresh)
  - id: SC-013-05
    name: Stop tracking on disappear
    given: Flight tracking is active
    when: ContentView is removed from the view hierarchy
    then: Flight tracking is stopped (location + auto-refresh)
---

# REQ-013: Adaptive Layout

## Description

The application adapts its navigation structure based on the device's horizontal size class, providing an optimal layout for both iPad (split view) and iPhone (tab view) form factors.

## Source Files

- `UpThere/Views/ContentView.swift` — Adaptive root container

## Acceptance Criteria

1. Layout selection is based on `horizontalSizeClass` from the environment
2. Regular size class (iPad): Uses `NavigationSplitView` with sidebar and detail
3. Compact size class (iPhone): Uses `TabView` with two tabs
4. Flight detail sheet is presented consistently across both layouts
5. Tracking lifecycle is managed at the root view level (start on appear, stop on disappear)
6. The sidebar column width is constrained: min 300pt, ideal 350pt, max 400pt

## iPad Layout (Regular Size Class)

```
┌──────────────────────────────────────────────┐
│ NavigationSplitView                          │
│ ┌────────────┬───────────────────────────────┐│
│ │ FlightList │ FlightMapView                 ││
│ │            │                               ││
│ │ - Sortable │ - Annotations                 ││
│ │ - Pull-to  │ - User location               ││
│ │   refresh  │ - Map controls                ││
│ │            │ - Refresh button              ││
│ │            │ - Error banner                ││
│ │            │                               ││
│ └────────────┴───────────────────────────────┘│
└──────────────────────────────────────────────┘
```

## iPhone Layout (Compact Size Class)

```
┌──────────────────────┐
│ TabView              │
│ ┌──────────────────┐ │
│ │ [Map] [Flights]  │ │  ← Tab bar
│ ├──────────────────┤ │
│ │ Active Tab View  │ │
│ │ (Map or Flights) │ │
│ │                  │ │
│ │                  │ │
│ └──────────────────┘ │
└──────────────────────┘
```

## Tab Configuration

| Tab | View | Icon |
|-----|------|------|
| Map | FlightMapView | `map` |
| Flights | FlightListView | `airplane` |

## Flight Selection Flow

Both layouts use the same selection mechanism:
1. `onFlightSelected` callback is triggered from either the list or map
2. `selectedFlightForDetail` state is updated in `ContentView`
3. `.sheet(item:)` presents `FlightDetailView`

## Lifecycle Management

| Event | Action |
|-------|--------|
| `onAppear` | `viewModel.startTracking()` — starts location updates and auto-refresh |
| `onDisappear` | `viewModel.stopTracking()` — stops location updates and auto-refresh |

## Edge Cases

- The size class check uses `horizontalSizeClass == .regular` for iPad detection
- Both the split view and tab view pass the same `onFlightSelected` handler to child views
- The `FlightMapView` in both layouts receives the same `viewModel` and handler
- The sidebar width constraints ensure the list doesn't consume too much or too little space on iPad
