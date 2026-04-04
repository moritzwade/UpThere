---
id: REQ-010
title: Flight List View
priority: high
type: feature
status: implemented
tags: [ui, list, sorting, navigation]
scenarios:
  - id: SC-010-01
    name: Display flight list
    given: Flights have been fetched successfully
    when: User views the flight list
    then: All flights are displayed in a scrollable list with callsign, altitude, speed, distance, and country
  - id: SC-010-02
    name: Sort by distance (default)
    given: Multiple flights are displayed
    when: The list is first shown (no user sorting selection)
    then: Flights are ordered by distance from the user's location, nearest first
  - id: SC-010-03
    name: Sort by callsign
    given: Flight list is displayed
    when: User selects "Callsign" from the sort menu
    then: Flights are ordered alphabetically by callsign
  - id: SC-010-04
    name: Sort by altitude
    given: Flight list is displayed
    when: User selects "Altitude" from the sort menu
    then: Flights are ordered by altitude descending (highest first)
  - id: SC-010-05
    name: Tap flight to show details
    given: Flight list is displayed
    when: User taps a flight row
    then: The flight detail sheet is presented for the selected flight
  - id: SC-010-06
    name: Show empty state
    given: No flights have been detected
    when: The flight list is displayed and not loading
    then: An empty state view with "No Flights" message is shown
  - id: SC-010-07
    name: Display flight count in title
    given: Flights have been fetched
    when: The flight list is displayed
    then: The navigation title shows "Flights (N)" where N is the count
---

# REQ-010: Flight List View

## Description

The flight list view displays all detected flights in a scrollable list with sorting capabilities, pull-to-refresh, and tap-to-view-details interaction.

## Source Files

- `UpThere/Views/FlightListView.swift` — List and row views
- `UpThere/ViewModels/UpThereViewModel.swift` — Flight data source

## Acceptance Criteria

1. Flights are displayed in a `List` with `.plain` list style
2. Each row shows: airplane icon (rotated by heading), callsign, altitude (ft), speed (kts), distance (km), and origin country
3. Default sort order is by distance (nearest first)
4. Sort options: Callsign, Altitude, Distance (via toolbar menu)
5. Current sort order is indicated with a checkmark in the menu
6. Pull-to-refresh is supported via `.refreshable`
7. Navigation title shows flight count: `"Flights (\(viewModel.flights.count))"`
8. Tapping a row triggers the `onFlightSelected` callback
9. Empty state is shown when `flights.isEmpty && !isLoading`

## Flight Row Layout (FlightRowView)

| Element | Position | Details |
|---------|----------|---------|
| Airplane icon | Left | Orange, rotated by `trueTrack`, 40pt fixed width |
| Callsign | Center-left | Headline, bold, trimmed and uppercased |
| Altitude | Center-left | Caption, secondary color, format: "X ft" |
| Speed | Center-left | Caption, secondary color, format: "X kts" |
| Distance | Right | Subheadline, medium weight, format: "X km" |
| Country | Right | Caption, secondary color |

## Sort Order Logic

| Sort | Comparison | Notes |
|------|-----------|-------|
| Distance | `distanceKm(from:)` ascending | Uses user location or default; nil treated as infinity |
| Callsign | `callsign` string comparison | Raw callsign (not formatted) |
| Altitude | `baroAltitude` descending | Nil treated as 0 |

## Empty State

| Element | Style |
|---------|-------|
| Icon | `airplane.circle`, 60pt, secondary color |
| Title | "No Flights", title2, semibold |
| Subtitle | "No flights detected in your area", caption, secondary color |

## Edge Cases

- Altitude and speed labels are conditionally shown (hidden if nil)
- Distance shows nil flights at the end of the sorted list
- Sort order state is local to the view (`@State private var sortOrder`)
- The list uses the raw `viewModel.flights.count` for the title, not the sorted count
