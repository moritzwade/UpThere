---
id: SYSREQ-001
title: Real-Time Flight Tracking
priority: high
type: feature
status: implemented
tags: [core, network, api, flights]
scenarios:
  - id: SC-001-01
    name: Fetch flights within bounding box
    given: User has granted location permission and OpenSky API is reachable
    when: The app requests a flight refresh
    then: Flights within the user's bounding box are fetched and displayed
  - id: SC-001-02
    name: Parse multiple flights from API response
    given: OpenSky API returns a valid response with multiple flight states
    when: The response is parsed
    then: Each valid flight state is converted to a Flight object
  - id: SC-001-03
    name: Handle empty flight response
    given: OpenSky API returns a valid response with no flight states
    when: The response is parsed
    then: An empty flight list is returned without error
  - id: SC-001-04
    name: Handle null states in response
    given: OpenSky API returns a valid response with null states
    when: The response is parsed
    then: An empty flight list is returned without error
  - id: SC-001-05
    name: Filter out invalid flight states
    given: OpenSky API response contains states with fewer than 17 elements or missing ICAO24
    when: The response is parsed
    then: Invalid states are silently skipped and valid states are converted to Flight objects
---

# SYSREQ-001: Real-Time Flight Tracking

## Description

The application fetches real-time flight data from the OpenSky Network API (`/states/all` endpoint) within a geographic bounding box centered on the user's location. Flight data is parsed from the API's raw array format into structured `Flight` model objects.

## Source Files

- `UpThere/Services/FlightService.swift` — API client actor
- `UpThere/Models/Flight.swift` — Flight data model
- `UpThere/Models/OpenSkyResponse.swift` — Response parsing and BoundingBox

## Acceptance Criteria

1. Flights are fetched from the OpenSky Network `/states/all` endpoint
2. The query is constrained by a geographic bounding box (lamin, lamax, lomin, lomax)
3. The response is parsed from raw JSON into `[Flight]` objects
4. Invalid or incomplete flight states are silently filtered out
5. Empty responses (no flights) are handled gracefully without error
6. The FlightService is an `actor` to ensure thread-safe concurrent access
7. The `URLSession` is configured with 30s request timeout and 60s resource timeout
8. Custom `URLSession` can be injected for testing purposes

## Bounding Box

The bounding box is calculated using `BoundingBox.around(latitude:longitude:radiusKm:)`:
- Centered on the user's current location (or default location if unavailable)
- Default radius is 200 km
- Converts km to degrees using approximate formulas:
  - Latitude: 1 degree ≈ 111 km
  - Longitude: 1 degree ≈ 111 km × cos(latitude)
- Generates 4 query parameters: `lamin`, `lamax`, `lomin`, `lomax`

## Flight Model

Each `Flight` contains:
| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `id` | `String` | state[0] | ICAO24 aircraft identifier (unique) |
| `callsign` | `String` | state[1] | Flight callsign |
| `originCountry` | `String` | state[2] | Country of registration |
| `lastContact` | `Date` | state[4] | Last position update timestamp |
| `longitude` | `Double?` | state[5] | Current longitude |
| `latitude` | `Double?` | state[6] | Current latitude |
| `baroAltitude` | `Double?` | state[7] | Barometric altitude in meters |
| `onGround` | `Bool` | state[8] | Whether aircraft is on ground |
| `velocity` | `Double?` | state[9] | Ground speed in m/s |
| `trueTrack` | `Double?` | state[10] | True track angle (0-360°) |
| `verticalRate` | `Double?` | state[11] | Vertical speed in m/s |
| `squawk` | `String?` | state[14] | Transponder squawk code |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `coordinate` | `CLLocationCoordinate2D?` | CoreLocation coordinate from lat/lon |
| `altitudeFeet` | `Double?` | Altitude in feet (m × 3.28084) |
| `speedKnots` | `Double?` | Speed in knots (m/s × 1.94384) |
| `verticalRateFPM` | `Double?` | Vertical rate in ft/min (m/s × 196.85) |
| `formattedCallsign` | `String` | Trimmed and uppercased callsign |
| `distanceKm(from:)` | `Double?` | Distance in km from a reference location |

## Edge Cases

- States with fewer than 17 elements are skipped
- States missing ICAO24 (index 0) are skipped
- States missing callsign (index 1) are skipped
- States missing origin_country (index 2) are skipped
- Numeric fields that are null in the API response become optional `nil` values
- The `NSNumber` to `Double` conversion is handled during parsing
