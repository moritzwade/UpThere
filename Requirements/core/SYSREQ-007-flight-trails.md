---
id: SYSREQ-007
title: Flight Trails
priority: medium
type: feature
status: implemented
tags: [core, map, trails, history, api]
scenarios:
  - id: SC-SYSREQ-007-01
    name: Accumulate trail positions on each refresh
    given: The app is tracking flights and a flight is visible on the map
    when: A new flight position is received during auto-refresh
    then: The position is appended to that flight's trail and old positions beyond 5 minutes are trimmed
  - id: SC-SYSREQ-007-02
    name: Fetch complete historical trail for selected flight
    given: A flight is selected and the OpenSky API is reachable
    when: The flight is selected
    then: The complete historical flight path is fetched from the API and displayed
  - id: SC-SYSREQ-007-03
    name: Expire trails for flights no longer in view
    given: A flight was visible but is no longer returned by the API
    when: The trail's most recent position is older than 5 minutes
    then: The trail is removed from the trails dictionary
  - id: SC-SYSREQ-007-04
    name: Clear trails when stopping tracking
    given: The app is tracking flights with accumulated trails
    when: The user stops tracking
    then: All trails and the selected flight trail are cleared
  - id: SC-SYSREQ-007-05
    name: Fall back to accumulated trail if API fails
    given: A flight is selected but the historical API request fails
    when: The API returns an error
    then: The accumulated client-side trail is used as a fallback
  - id: SC-SYSREQ-007-06
    name: Trim trail to 5-minute window
    given: A flight has accumulated positions over multiple refresh cycles
    when: A new position is added that makes older positions exceed 5 minutes
    then: Positions older than 5 minutes from the most recent are removed
---

# SYSREQ-007: Flight Trails

## Description

The application displays recent flight paths/trajectories on the map for each aircraft. Trails are built using a hybrid approach:

1. **Accumulated trails (client-side)**: For all visible flights, positions are accumulated from each 5-second refresh cycle. Only the last 5 minutes of positions are kept.
2. **Complete historical trail (API)**: When a flight is selected, the full historical path is fetched from the OpenSky Network API (`/api/states/all` endpoint with `icao24`, `time`, and `endTime` parameters).

This approach minimizes API calls — no extra calls are needed for regular trails, and only one call is made when a flight is selected.

## Source Files

- `UpThere/Models/FlightTrail.swift` — Trail data model
- `UpThere/Models/OpenSkyResponse.swift` — `OpenSkyHistoryResponse` parsing
- `UpThere/Services/FlightService.swift` — `fetchFlightHistory(icao24:timeFrom:timeTo:)` method
- `UpThere/ViewModels/UpThereViewModel.swift` — Trail accumulation, `selectedFlightTrail`, `fetchSelectedFlightTrail()`

## Acceptance Criteria

1. A `FlightTrail` model stores ordered timestamped positions per ICAO24 identifier
2. Trails accumulate positions on each `refreshFlights()` call without additional API calls
3. Accumulated trails are trimmed to a rolling 5-minute window
4. Trails for flights no longer in view are expired after 5 minutes
5. Selecting a flight triggers a single API call to fetch complete historical data (last 24 hours)
6. If the API call fails, the accumulated trail is used as a fallback
7. All trails are cleared when tracking is stopped
8. The `OpenSkyHistoryResponse` is parsed from the same raw array format as the live states endpoint
9. The `FlightService.fetchFlightHistory` method handles auth, token refresh, rate limiting, and errors

## FlightTrail Model

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | ICAO24 identifier (same as `Flight.id`) |
| `positions` | `[(date: Date, coordinate: CLLocationCoordinate2D)]` | Ordered timestamped positions (oldest first) |
| `isCompleteHistory` | `Bool` | Whether this trail was fetched from the API |
| `coordinates` | `[CLLocationCoordinate2D]` | Array of coordinates for MapKit polyline rendering |
| `isValid` | `Bool` | True if at least 2 positions exist |
| `positionCount` | `Int` | Number of positions in the trail |
| `coordinateRegion` | `MKCoordinateRegion?` | Region encompassing all positions with 20% padding |

### Methods

| Method | Description |
|--------|-------------|
| `append(date:coordinate:)` | Add a position; auto-trims if not complete history |
| `setCompleteHistory(positions:)` | Replace trail with API data; disables auto-trimming |
| `resetToAccumulated()` | Re-enable auto-trimming and trim to 5-minute window |

## Trail Rendering

| Trail Type | Color | Line Width | Source |
|------------|-------|------------|--------|
| Accumulated (non-selected) | Orange 35% opacity | 1.5pt | Client-side accumulation |
| Accumulated (selected) | Orange 100% opacity | 2.5pt | Client-side accumulation |
| Complete history | Orange 100% opacity | 3.0pt | API fetch |

## OpenSky History API

- Endpoint: `GET /api/states/all?icao24={id}&time={from}&endTime={to}`
- Returns the same array format as `/states/all`
- Requires authentication (OAuth2 Bearer token)
- Subject to rate limiting (429)
- Time range: up to 24 hours for free tier

## Edge Cases

- Positions with invalid coordinates (outside -90/90 lat, -180/180 lon) are filtered out
- Duplicate positions at the same timestamp are skipped
- Empty history responses return an empty positions array
- Token expiration during history fetch triggers automatic refresh and retry
