---
id: NFREQ-001
title: Performance
priority: medium
type: non-functional
status: implemented
tags: [performance, api, rate-limits, timeout]
scenarios:
  - id: SC-020-01
    name: Respect API request timeout
    given: The OpenSky API is slow or unresponsive
    when: A flight fetch request is made
    then: The request times out after 30 seconds
  - id: SC-020-02
    name: Respect API resource timeout
    given: The OpenSky API connection is established but data transfer is slow
    when: A flight fetch request is made
    then: The resource times out after 60 seconds
  - id: SC-020-03
    name: Handle API rate limiting
    given: The app exceeds the OpenSky API rate limit
    when: A flight fetch is attempted
    then: A rate limited error is thrown and displayed to the user
  - id: SC-020-04
    name: Use bounding box to limit API scope
    given: User location is available
    when: A flight fetch is made
    then: Only flights within the configured search radius are requested from the API
---

# NFREQ-001: Performance

## Description

The application is designed to perform efficiently within the constraints of the OpenSky Network API, including rate limits, timeouts, and geographic scoping.

## Source Files

- `UpThere/Services/FlightService.swift` — Timeout configuration, rate limit handling
- `UpThere/Models/OpenSkyResponse.swift` — Bounding box optimization
- `UpThere/ViewModels/UpThereViewModel.swift` — Refresh interval and concurrent request prevention

## Acceptance Criteria

1. `URLSession` request timeout is 30 seconds (`timeoutIntervalForRequest`)
2. `URLSession` resource timeout is 60 seconds (`timeoutIntervalForResource`)
3. API queries are scoped to a geographic bounding box to reduce response size
4. Default search radius is 200 km (configurable via `searchRadiusKm`)
5. Auto-refresh interval is 5 seconds (configurable via `refreshInterval`)
6. Concurrent flight fetches are prevented (`isLoading` guard)
7. Rate limit (HTTP 429) responses are handled gracefully
8. Token caching reduces unnecessary authentication requests

## Timeout Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| `timeoutIntervalForRequest` | 30s | Maximum time for the initial request to be sent |
| `timeoutIntervalForResource` | 60s | Maximum time for the entire resource transfer |

## Rate Limiting

| Mode | Approximate Limit | Notes |
|------|-------------------|-------|
| Anonymous (no credentials) | Lower | OpenSky restricts anonymous access |
| Authenticated (with credentials) | Higher | Requires valid OAuth2 token |

When rate limited (HTTP 429), the app throws `OpenSkyError.rateLimited` and displays an error banner.

## Bounding Box Optimization

The bounding box reduces API response size by only requesting flights within the user's area:
- Default radius: 200 km
- Converts to latitude/longitude ranges using approximate degree-per-km formulas
- Generates 4 query parameters for the API

## Edge Cases

- The auto-refresh loop sleeps between requests, not fires at fixed intervals
- If a request takes longer than the refresh interval, the next refresh is skipped (isLoading guard)
- Token expiry includes a 60-second safety margin to avoid using nearly-expired tokens
