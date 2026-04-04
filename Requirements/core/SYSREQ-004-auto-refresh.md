---
id: SYSREQ-004
title: Auto-Refresh
priority: medium
type: feature
status: implemented
tags: [core, refresh, background, timer]
scenarios:
  - id: SC-004-01
    name: Start auto-refresh on tracking start
    given: User has started flight tracking
    when: The tracking session begins
    then: Flights are automatically refreshed at the configured interval
  - id: SC-004-02
    name: Default refresh interval is 5 seconds
    given: No custom refresh interval is configured
    when: Auto-refresh is active
    then: Flights are fetched every 5 seconds
  - id: SC-004-03
    name: Stop auto-refresh on tracking stop
    given: Auto-refresh is active
    when: The user stops flight tracking
    then: The auto-refresh loop is cancelled and no further requests are made
  - id: SC-004-04
    name: Perform immediate fetch on start
    given: User has just started flight tracking
    when: Tracking begins
    then: An immediate flight fetch is performed before the first interval wait
  - id: SC-004-05
    name: Skip refresh if already loading
    given: A flight fetch is currently in progress
    when: The auto-refresh timer fires
    then: The new refresh is skipped until the current fetch completes
---

# SYSREQ-004: Auto-Refresh

## Description

The application automatically refreshes flight data at a configurable interval. The auto-refresh loop starts when tracking begins and stops cleanly when tracking ends. An immediate fetch is performed on start, followed by periodic fetches.

## Source Files

- `UpThere/ViewModels/UpThereViewModel.swift` — Auto-refresh loop management

## Acceptance Criteria

1. Auto-refresh is started by `startTracking()` and stopped by `stopTracking()`
2. Default refresh interval is 5 seconds (`refreshInterval: TimeInterval = 5`)
3. The refresh interval is configurable via `searchRadiusKm` property
4. An immediate flight fetch is performed when tracking starts (before the first interval)
5. The auto-refresh uses a cancellable `Task` loop with `Task.sleep`
6. The refresh task is properly cancelled when `stopTracking()` is called
7. Concurrent refreshes are prevented (guard `!isLoading` in `refreshFlights()`)
8. The `lastUpdateTime` is updated on each successful refresh

## Auto-Refresh Loop Implementation

```swift
refreshTask = Task { [weak self] in
    while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: UInt64(self.refreshInterval * 1_000_000_000))
        if !Task.isCancelled {
            await self.refreshFlights()
        }
    }
}
```

The loop checks `Task.isCancelled` both before sleeping and after waking to ensure clean cancellation.

## Lifecycle

```
[startTracking()]
  → startAutoRefresh() → immediate fetch → sleep(interval) → fetch → sleep(interval) → ...
  → startUpdatingLocation()

[stopTracking()]
  → stopAutoRefresh() → cancel task → stopUpdatingLocation()
```

## Edge Cases

- `stopAutoRefresh()` calls `stopAutoRefresh()` first to prevent duplicate tasks
- The refresh loop uses `[weak self]` to avoid retain cycles
- If a fetch is already in progress (`isLoading == true`), the auto-refresh is effectively skipped
- Task cancellation is checked after sleep to avoid unnecessary fetches during shutdown
