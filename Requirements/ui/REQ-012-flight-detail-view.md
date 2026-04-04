---
id: REQ-012
title: Flight Detail View
priority: medium
type: feature
status: implemented
tags: [ui, detail, sheet, information]
scenarios:
  - id: SC-012-01
    name: Display flight details
    given: A flight is selected from the list or map
    when: The detail sheet is presented
    then: The flight's callsign, aircraft ID, country, altitude, speed, heading, and coordinates are displayed
  - id: SC-012-02
    name: Close detail sheet
    given: The flight detail sheet is visible
    when: User taps the "Done" button
    then: The sheet is dismissed
  - id: SC-012-03
    name: Handle missing optional fields
    given: A flight has missing optional data (e.g., no altitude or speed)
    when: The detail sheet is displayed
    then: Only available fields are shown; missing fields are hidden
  - id: SC-012-04
    name: Display rotated airplane icon
    given: A flight with a valid trueTrack is selected
    when: The detail sheet is displayed
    then: The header shows a large airplane icon rotated by the flight's heading
---

# REQ-012: Flight Detail View

## Description

The flight detail view is presented as a modal sheet when a flight is selected from either the list or map. It displays comprehensive information about the selected flight organized into sections.

## Source Files

- `UpThere/Views/FlightDetailView.swift` — Detail sheet view

## Acceptance Criteria

1. The detail view is presented as a `.sheet` from `ContentView`
2. The view is wrapped in a `NavigationStack` with a "Done" button in the toolbar
3. Content is scrollable via `ScrollView`
4. Information is organized into three sections: Flight Information, Position, Coordinates
5. Sections are separated by `Divider` views
6. Optional fields (altitude, speed, heading, coordinates) are conditionally displayed

## Layout Structure

```
┌─────────────────────────────────┐
│ Navigation: "Flight Details" [Done]
├─────────────────────────────────┤
│         [Airplane Icon]          │  ← 60pt, orange, rotated by trueTrack
│           CALLSIGN               │  ← title2, bold
│    (orange tinted background)    │
├─────────────────────────────────┤
│ Flight Information               │  ← headline
│ Callsign:        CALLSIGN        │
│ Aircraft ID:     abc123          │
│ Country:         United States   │
├─────────────────────────────────┤
│ Position                         │  ← headline
│ Altitude:        35,000 ft       │  ← conditional
│ Speed:           450 knots       │  ← conditional
│ Heading:         270°            │  ← conditional
├─────────────────────────────────┤
│ Coordinates                      │  ← headline
│ Latitude:        37.774900°      │  ← 6 decimal places
│ Longitude:       -122.419400°    │  ← 6 decimal places
└─────────────────────────────────┘
```

## Data Display

| Section | Field | Format | Condition |
|---------|-------|--------|-----------|
| Header | Callsign | `formattedCallsign` (trimmed, uppercased) | Always |
| Header | Airplane icon | 60pt, orange, rotated by `trueTrack` | Always |
| Flight Information | Callsign | `formattedCallsign` | Always |
| Flight Information | Aircraft ID | `flight.id` (ICAO24) | Always |
| Flight Information | Country | `flight.originCountry` | Always |
| Position | Altitude | `altitudeFeet` as "X ft" | If `altitudeFeet != nil` |
| Position | Speed | `speedKnots` as "X knots" | If `speedKnots != nil` |
| Position | Heading | `trueTrack` as "X°" | If `trueTrack != nil` |
| Coordinates | Latitude | `latitude` as "X.XXXXXX°" | If `latitude != nil` |
| Coordinates | Longitude | `longitude` as "X.XXXXXX°" | If `longitude != nil` |

## Edge Cases

- Altitude, speed, and heading rows are entirely hidden when their values are nil
- Coordinates rows are entirely hidden when their values are nil
- The sheet is presented via `ContentView`'s `selectedFlightForDetail` state, not directly from the list or map
- The `@Environment(\.dismiss)` is used for the Done button action
- Bottom padding of 40pt ensures content is not obscured by safe area
