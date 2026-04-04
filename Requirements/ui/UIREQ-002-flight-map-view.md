---
id: UIREQ-002
title: Flight Map View
priority: high
type: feature
status: implemented
tags: [ui, map, annotations, navigation]
scenarios:
  - id: SC-011-01
    name: Display flight annotations on map
    given: Flights have been fetched with valid coordinates
    when: The map view is displayed
    then: Each flight appears as an airplane annotation rotated by its heading
  - id: SC-011-02
    name: Show user location on map
    given: User location is available
    when: The map view is displayed
    then: A blue dot annotation with white border marks the user's position
  - id: SC-011-03
    name: Center map on user location
    given: User location becomes available for the first time
    when: The location is received
    then: The map camera centers on the user location with a 150km region
  - id: SC-011-04
    name: Highlight selected flight annotation
    given: A flight is selected from the list or map
    when: The map view is displayed
    then: The selected flight's annotation has an orange highlight background and thicker border
  - id: SC-011-05
    name: Tap annotation to select flight
    given: Flight annotations are visible on the map
    when: User taps a flight annotation
    then: The flight detail sheet is presented for the selected flight
  - id: SC-011-06
    name: Refresh on map camera change
    given: The map view is displayed
    when: User finishes panning or zooming the map
    then: Flights are refreshed for the new map region
  - id: SC-011-07
    name: Display error banner on map
    given: A flight fetch error occurs
    when: The error is set on the view model
    then: An orange error banner appears at the bottom of the map
---

# UIREQ-002: Flight Map View

## Description

The map view displays flights as interactive airplane annotations on an Apple MapKit map, with user location, map controls, and overlay UI elements for refresh and error display.

## Source Files

- `UpThere/Views/FlightMapView.swift` — Map view and annotation views
- `UpThere/ViewModels/UpThereViewModel.swift` — Flight data source

## Acceptance Criteria

1. Flights with valid coordinates are displayed as `Annotation` views on the map
2. Each annotation shows an airplane icon rotated by the flight's `trueTrack`
3. User location is shown as a blue circle (12pt) with a white 2pt stroke border
4. Map controls include: `MapUserLocationButton`, `MapCompass`, `MapScaleView`
5. Map camera centers on user location when first available (150,000m region)
6. Flights are refreshed when the map camera changes (`.onEnd` frequency)
7. A floating refresh button appears in the top-right corner
8. An error banner appears at the bottom when `viewModel.errorMessage` is non-nil
9. Selected flight annotation is visually highlighted

## Annotation Styling

| State | Background | Border | Shadow |
|-------|-----------|--------|--------|
| Normal | White, 0.9 opacity | Gray, 1pt, 0.3 opacity | 2pt radius |
| Selected | Orange, 0.3 opacity | Orange, 3pt | 2pt radius |

## UI Overlay Layout

```
┌─────────────────────────────┐
│                    [Refresh]│  ← Top-right, offset (20, 40)
│                             │
│                             │
│                             │
│                             │
│  [Error Banner]             │  ← Bottom, full-width
└─────────────────────────────┘
```

## Refresh Button States

| State | Appearance |
|-------|-----------|
| Idle | `arrow.clockwise` icon, 10pt padding, regularMaterial circle background |
| Loading | `ProgressView()`, 44x44pt frame |

## Error Banner

| Property | Value |
|----------|-------|
| Icon | `exclamationmark.triangle.fill` |
| Background | Orange, 0.9 opacity |
| Text color | White |
| Font | Caption |
| Corners | 10pt radius |
| Position | Bottom of map, padded |

## Edge Cases

- Flights without valid coordinates are not displayed on the map
- The initial camera center only happens once (`hasInitialLocationSet` flag)
- The navigation title is "Flights" with `.inline` display mode on iOS
- Map controls are built-in MapKit components (not custom overlays)
- The `FlightSelectionHandler` callback is used for both annotation taps and list selection
