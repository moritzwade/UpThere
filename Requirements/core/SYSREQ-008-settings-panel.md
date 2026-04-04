---
id: SYSREQ-008
title: Settings Panel
priority: high
type: feature
status: implemented
tags: [settings, persistence, configuration, user-preferences, units]
scenarios:
  - id: SC-SYSREQ-008-01
    name: Open settings panel
    given: The app is running
    when: User taps the gear icon in the toolbar
    then: The settings sheet is presented with all configuration sections
  - id: SC-SYSREQ-008-02
    name: Change search radius
    given: The settings panel is open
    when: User selects a different search radius option
    then: The new radius is persisted and used for subsequent flight fetches
  - id: SC-SYSREQ-008-03
    name: Change refresh interval to manual
    given: Auto-refresh is active with a preset interval
    when: User selects "Manual" in the refresh options
    then: Auto-refresh is disabled and only manual refreshes are possible
  - id: SC-SYSREQ-008-04
    name: Set custom refresh interval
    given: The settings panel is open
    when: User selects "Custom" and enters a number of seconds
    then: Auto-refresh uses the custom interval
  - id: SC-SYSREQ-008-05
    name: Change map style
    given: The settings panel is open
    when: User selects a different map style
    then: The map view immediately applies the new style
  - id: SC-SYSREQ-008-06
    name: Configure custom API credentials
    given: The settings panel is open
    when: User enters a Client ID and Client Secret
    then: The credentials are persisted and used for authentication, overriding environment variables
  - id: SC-SYSREQ-008-07
    name: Settings persist across app restarts
    given: User has changed one or more settings
    when: The app is closed and reopened
    then: All previously saved settings are restored
  - id: SC-SYSREQ-008-08
    name: Clear custom API credentials
    given: Custom API credentials are configured
    when: User taps "Clear Credentials"
    then: Both Client ID and Client Secret are cleared and the app falls back to environment variables
  - id: SC-SYSREQ-008-09
    name: Change altitude unit
    given: The settings panel is open
    when: User changes altitude unit between meters and feet
    then: The flight detail view displays altitude in the selected unit
  - id: SC-SYSREQ-008-10
    name: Change speed unit
    given: The settings panel is open
    when: User changes speed unit between km/h and knots
    then: The flight detail view displays speed in the selected unit
  - id: SC-SYSREQ-008-11
    name: Close settings panel
    given: The settings panel is open
    when: User taps the "Done" button
    then: The settings sheet is dismissed
---

# SYSREQ-008: Settings Panel

## Description

The application provides a settings panel that allows users to configure search radius, auto-refresh interval, map style, unit preferences (altitude and speed), and custom API credentials. All settings are persisted via `UserDefaults` and survive app restarts, development rebuilds, and App Store updates.

## Source Files

- `UpThere/Models/AppSettings.swift` — Settings model and persistence
- `UpThere/Views/SettingsView.swift` — Settings UI
- `UpThere/Views/ContentView.swift` — Settings sheet presentation
- `UpThere/Services/OpenSkyConfig.swift` — `ResolvedCredentials` struct and resolution logic
- `UpThere/Services/FlightService.swift` — Credential-based initialization
- `UpThere/ViewModels/UpThereViewModel.swift` — Settings observation and reactive updates

## Acceptance Criteria

1. Settings are accessible via a gear icon button in the toolbar
2. Settings are presented as a sheet with a `NavigationStack` and `Form` layout
3. A "Done" button in the toolbar dismisses the settings sheet
4. Six configuration sections are available: Search Radius, Auto-Refresh, Map Style, Units, API Credentials
5. All settings are persisted to `UserDefaults` with keys prefixed `upthere.`
6. Settings changes take effect reactively without requiring an app restart
7. The `AppSettings` class is `@Observable` and `@MainActor`
8. The `FlightService` receives `ResolvedCredentials` (a plain struct) to avoid MainActor isolation conflicts

## Search Radius

| Option | Value |
|--------|-------|
| 50 km | 50 |
| 100 km | 100 |
| 200 km | 200 (default) |
| 500 km | 500 |

Presented as a `.segmented` picker. The selected value is used as `radiusKm` when building the `BoundingBox` in `refreshFlights()`.

## Auto-Refresh Interval

| Option | Interval |
|--------|----------|
| Often | 5 seconds |
| Medium | 30 seconds |
| Seldom | 60 seconds |
| Manual | Disabled (nil) |
| Custom | User-defined seconds (minimum 1) |

Presented as a `.menu` picker. When "Custom" is selected, a `TextField` appears for entering the number of seconds. When "Manual" is selected, a hint text explains that the user must tap the refresh button manually.

The `effectiveRefreshInterval` computed property returns `nil` for manual mode, which causes `startAutoRefresh()` to skip creating a refresh task.

## Map Style

| Option | MapStyle |
|--------|----------|
| Standard (default) | `.standard` |
| Satellite | `.imagery` |
| Hybrid | `.hybrid` |

Presented as a `.segmented` picker. Applied to the map via `.mapStyle(settings.mapStyle.mapStyle)` modifier on `FlightMapView`.

## Unit Preferences

### Altitude Unit

| Option | Symbol | Default |
|--------|--------|---------|
| Meters (m) | m | Yes |
| Feet (ft) | ft | No |

The `Flight` model stores altitude in meters (`baroAltitude`) and provides `altitudeFeet` as a computed property. The detail view selects which to display based on the user's preference.

### Speed Unit

| Option | Symbol | Default |
|--------|--------|---------|
| km/h | km/h | Yes |
| Knots (kt) | kt | No |

The `Flight` model stores speed in m/s (`velocity`) and provides `speedKnots` and `speedKmh` as computed properties. The detail view selects which to display based on the user's preference.

## API Credentials

| Field | UI Element | Notes |
|-------|-----------|-------|
| Client ID | `TextField` | Autocapitalization disabled (iOS), autocorrection disabled |
| Client Secret | `SecureField` | Masked input |

- A "Clear Credentials" destructive button appears when credentials are set
- Info text explains that custom credentials override environment variables
- Link to opensky-network.org for obtaining credentials

## Credential Resolution Priority

```
1. Custom settings (Client ID + Client Secret from UserDefaults)
   ↓ if not configured
2. Environment variables (OPENSKY_CLIENT_ID + OPENSKY_CLIENT_SECRET)
   ↓ if not configured
3. None — unauthenticated mode
```

The credential source is logged at `info` level on first use:
```
Using API credentials from: custom settings
Using API credentials from: environment variables
Using API credentials from: none — unauthenticated
```

## Settings Observation

The `UpThereViewModel` polls settings every 500ms via `observeSettingsChanges()` to detect:
- **Refresh option changes** → restarts the auto-refresh task with the new interval
- **Credential changes** → calls `flightService.updateCredentials()` with resolved credentials, clearing the cached token if the source changed

## Persistence Keys

| Key | Type | Default |
|-----|------|---------|
| `upthere.searchRadius` | Double | 200 |
| `upthere.refreshOption` | String | "often" |
| `upthere.customRefreshSeconds` | Double | 10 |
| `upthere.mapStyle` | String | "standard" |
| `upthere.altitudeUnit` | String | "meters" |
| `upthere.speedUnit` | String | "kmh" |
| `upthere.customClientId` | String | "" |
| `upthere.customClientSecret` | String | "" |

## Settings View Layout

```
┌─────────────────────────────────┐
│ Settings              [Done]    │
├─────────────────────────────────┤
│ Search Radius                   │
│ [50 km][100 km][200 km][500 km] │
├─────────────────────────────────┤
│ Auto-Refresh                    │
│ Interval: [Often (5 s)      ▼]  │
├─────────────────────────────────┤
│ Map Style                       │
│ [Standard][Satellite][Hybrid]   │
├─────────────────────────────────┤
│ Units                           │
│ Altitude: [Meters (m)       ▼]  │
│ Speed:    [km/h             ▼]  │
├─────────────────────────────────┤
│ API Credentials                 │
│ Client ID: [____________]       │
│ Client Secret: [____________]   │
│ ⓘ Overrides environment vars    │
│ Get credentials at opensky-...  │
└─────────────────────────────────┘
```

## Edge Cases

- Custom refresh seconds below 1 are clamped to 1
- Changing credentials clears the cached OAuth2 token to force re-authentication
- Settings are initialized from `UserDefaults` on app launch; missing keys use defaults
- The `AppSettings` singleton (`shared`) is created at the `@main` app root and injected through the view hierarchy
- The `FlightService` stores `ResolvedCredentials` (a plain struct) rather than `AppSettings` directly to avoid `@MainActor` isolation conflicts
- Unit preferences affect only the display layer (`FlightDetailView`), not the underlying data model
