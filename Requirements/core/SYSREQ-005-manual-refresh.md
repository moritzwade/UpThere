---
id: SYSREQ-005
title: Manual Refresh
priority: medium
type: feature
status: implemented
tags: [core, refresh, user-action]
scenarios:
  - id: SC-005-01
    name: Pull-to-refresh in flight list
    given: The flight list is visible
    when: User pulls down on the list
    then: Flights are refreshed and the loading indicator is shown
  - id: SC-005-02
    name: Refresh button on map view
    given: The map view is visible
    when: User taps the refresh button
    then: Flights are refreshed and a progress indicator is shown during loading
  - id: SC-005-03
    name: Map camera change triggers refresh
    given: The map view is visible
    when: User pans or zooms the map
    then: Flights are refreshed for the new map region
  - id: SC-005-04
    name: Prevent concurrent manual refreshes
    given: A flight refresh is already in progress
    when: User triggers another manual refresh
    then: The second refresh is ignored until the first completes
---

# SYSREQ-005: Manual Refresh

## Description

Users can manually trigger a flight data refresh through multiple UI interactions: pull-to-refresh in the list view, a dedicated refresh button on the map view, and automatic refresh when the map camera changes (pan/zoom).

## Source Files

- `UpThere/Views/FlightListView.swift` — Pull-to-refresh
- `UpThere/Views/FlightMapView.swift` — Refresh button and camera-change refresh
- `UpThere/ViewModels/UpThereViewModel.swift` — `refreshFlights()` method

## Acceptance Criteria

1. **Pull-to-refresh**: The flight list supports `.refreshable { await viewModel.refreshFlights() }`
2. **Refresh button**: A floating button on the map view triggers `viewModel.refreshFlights()`
3. **Camera-change refresh**: When the map camera changes (`onMapCameraChange` with `.onEnd` frequency), flights are refreshed
4. **Loading state**: During refresh, `isLoading` is `true` and the UI shows appropriate indicators
5. **Concurrent prevention**: `refreshFlights()` guards against concurrent calls with `guard !isLoading else { return }`
6. **Error clearing**: `errorMessage` is cleared at the start of each refresh attempt

## UI Elements

| View | Element | Behavior |
|------|---------|----------|
| FlightListView | `.refreshable` modifier | Pull-down gesture triggers refresh |
| FlightMapView | Refresh button (top-right) | Shows `ProgressView()` while loading, `arrow.clockwise` icon when idle |
| FlightMapView | `onMapCameraChange` | Triggers refresh when user finishes panning/zooming |

## Refresh Flow

```
[User triggers refresh]
  → guard !isLoading
  → isLoading = true, errorMessage = nil
  → Determine location (user location or default)
  → Build bounding box
  → Fetch flights from API
  → Update flights array
  → Update lastUpdateTime
  → isLoading = false
  → On error: set errorMessage
```

## Edge Cases

- Pull-to-refresh and button refresh both call the same `refreshFlights()` method
- Map camera refresh happens after the camera change ends (`.onEnd` frequency), not during continuous movement
- If a refresh fails, the error message is displayed but the previous flight data remains visible
- The refresh button shows a `ProgressView` during loading instead of the arrow icon
