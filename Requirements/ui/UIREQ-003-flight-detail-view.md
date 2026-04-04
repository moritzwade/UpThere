---
id: UIREQ-003
title: Flight Detail View
priority: medium
type: feature
status: implemented
tags: [ui, detail, sheet, information, route, airline]
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
  - id: SC-012-05
    name: Display airline logo and route info
    given: A flight is selected and route data is available from AviationStack API
    when: The detail sheet is displayed
    then: The header shows the airline logo (or ICAO designator badge as fallback), route (e.g., "LAX → BOS"), and flight status badge
  - id: SC-012-06
    name: Display route section with origin, destination, and ETA
    given: A flight is selected and route data is available
    when: The detail sheet is displayed
    then: A "Route" section shows airline name, origin airport, destination airport, and estimated arrival time
  - id: SC-012-07
    name: Show loading state for route info
    given: A flight is selected and route data is being fetched
    when: The detail sheet is displayed
    then: A "Loading route info..." progress indicator is shown in the Route section
  - id: SC-012-08
    name: Hide route section when no data available
    given: A flight is selected but no route data is available (API not configured or no match)
    when: The detail sheet is displayed
    then: The Route section is not shown
---

# UIREQ-003: Flight Detail View

## Description

The flight detail view is presented as a modal sheet when a flight is selected from either the list or map. It displays comprehensive information about the selected flight organized into sections, including airline branding and route information when available.

## Source Files

- `UpThere/Views/FlightDetailView.swift` — Detail sheet view
- `UpThere/Models/FlightRouteInfo.swift` — Route data model
- `UpThere/Services/FlightRouteService.swift` — AviationStack API service
- `UpThere/ViewModels/UpThereViewModel.swift` — Route fetching orchestration

## Acceptance Criteria

1. The detail view is presented as a `.sheet` from `ContentView`
2. The view is wrapped in a `NavigationStack` with a "Done" button in the toolbar
3. Content is scrollable via `ScrollView`
4. Information is organized into sections: Route (if available), Flight Information, Position, Coordinates
5. Sections are separated by `Divider` views
6. Optional fields (altitude, speed, heading, coordinates) are conditionally displayed
7. Airline logo is fetched from `https://images.kiwi.com/airlines/64/{IATA}.png` with fallback to ICAO designator badge
8. Route section is only shown when route data is available or while loading

## Layout Structure

```
┌─────────────────────────────────┐
│ Navigation: "Flight Details" [Done]
├─────────────────────────────────┤
│   [Logo] [Airplane Icon]         │  ← Logo or ICAO badge + 60pt rotated airplane
│           CALLSIGN               │  ← title2, bold
│         LAX → BOS                │  ← route (if available)
│        [En Route]                │  ← status badge (if available)
│    (orange tinted background)    │
├─────────────────────────────────┤
│ Trail Map (if available)         │  ← 200px height map with trail
├─────────────────────────────────┤
│ Route (conditional)              │  ← headline, only if data available
│ Airline:         United (UAL)    │
│ Origin:          LAX             │
│                  Los Angeles Intl│
│ Destination:     BOS             │
│                  Logan Intl      │
│ Est. Arrival:    4:25 PM         │
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
| Header | Airline logo | `AsyncImage` from kiwi.com or ICAO badge | If route data with IATA code |
| Header | Callsign | `formattedCallsign` (trimmed, uppercased) | Always |
| Header | Route | `formattedRoute` (e.g., "LAX → BOS") | If route data available |
| Header | Status badge | `displayStatus` with color | If route data with status |
| Route | Airline | `formattedAirline` (e.g., "United Airlines (UAL)") | If route data with airline |
| Route | Origin | `departureAirportIata` + `departureAirportName` | If route data with departure |
| Route | Destination | `arrivalAirportIata` + `arrivalAirportName` | If route data with arrival |
| Route | Est. Arrival | `estimatedArrival` or `scheduledArrival` as time | If route data with arrival time |
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
- The Route section is hidden entirely when no route data is available and not loading
- A loading indicator is shown in the Route section while route data is being fetched
- If airline logo fails to load, an ICAO designator badge (e.g., "UAL" in monospaced text) is shown
- If no airline designator can be extracted from callsign, a generic airplane icon is shown
- The sheet is presented via `ContentView`'s `showDetail` binding, triggered by `viewModel.selectedFlight`
- The `@Environment(\.dismiss)` is used for the Done button action
- Bottom padding of 40pt ensures content is not obscured by safe area
- Route info is fetched asynchronously when a flight is selected and cached in-memory
