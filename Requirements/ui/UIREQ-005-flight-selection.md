---
id: UIREQ-005
title: Flight Selection
priority: high
type: feature
status: implemented
tags: [ui, map, list, selection, interaction]
scenarios:
  - id: SC-UIREQ-005-01
    name: Select a flight by tapping on the map
    given: The map view displays one or more flight markers
    when: The user taps a flight marker
    then: The flight is selected, highlighted on the map, and its complete trail is fetched
  - id: SC-UIREQ-005-02
    name: Select a flight by tapping in the list
    given: The flight list displays one or more flights
    when: The user taps a flight row
    then: The flight is selected and highlighted in both the list and the map
  - id: SC-UIREQ-005-03
    name: Deselect by tapping the same flight
    given: A flight is currently selected
    when: The user taps the same flight again (in list or map)
    then: The flight is deselected and the complete trail is hidden
  - id: SC-UIREQ-005-04
    name: Deselect by tapping empty map space
    given: A flight is currently selected
    when: The user taps an empty area on the map
    then: The flight is deselected and the complete trail is hidden
  - id: SC-UIREQ-005-05
    name: Switch selection to another flight
    given: Flight A is currently selected
    when: The user taps Flight B (in list or map)
    then: Flight A is deselected, Flight B is selected and its complete trail is fetched
  - id: SC-UIREQ-005-06
    name: Open detail view for selected flight
    given: A flight is currently selected
    when: The user taps the info button
    then: The flight detail sheet opens showing the trail map and flight information
  - id: SC-UIREQ-005-07
    name: Selection syncs across list and map
    given: A flight is selected from the map view
    when: The user switches to the list view (or uses split view on iPad)
    then: The same flight is highlighted in the list with a checkmark and info button
---

# UIREQ-005: Flight Selection

## Description

The application provides a unified flight selection mechanism that works across the map view, list view, and split view (iPad/Mac). Selecting a flight highlights it everywhere and triggers fetching of its complete historical trail. Deselection is possible through multiple intuitive interactions.

## Source Files

- `UpThere/Views/ContentView.swift` — Central selection wiring, detail sheet management
- `UpThere/Views/FlightMapView.swift` — Map annotation tap, map background tap, floating detail button
- `UpThere/Views/FlightListView.swift` — Row tap, checkmark indicator, detail button, row highlight
- `UpThere/ViewModels/UpThereViewModel.swift` — `selectedFlight`, `selectFlight(_:)` with toggle logic

## Acceptance Criteria

1. Tapping a flight marker on the map selects it
2. Tapping a flight row in the list selects it
3. Tapping the same flight again deselects it (toggle behavior)
4. Tapping empty space on the map deselects the current flight
5. Selecting a different flight switches selection (old deselects, new selects)
6. Selection is synchronized across all views (map, list, split view)
7. The selected flight is visually highlighted in both the map and list
8. A floating "Details" button appears on the map when a flight is selected
9. An "Info" button appears in the list row for the selected flight
10. Opening the detail sheet shows the complete trail map and flight information
11. Selection state is cleared when tracking is stopped

## Visual Design

### Map View

| Element | Unselected | Selected |
|---------|------------|----------|
| Marker | Orange airplane, white circle, gray stroke | Orange airplane, orange-tinted circle, orange stroke (3pt) |
| Trail | Dim orange polyline (35% opacity, 1.5pt) | Bright orange complete trail (100% opacity, 3.0pt) |
| Detail button | Hidden | Floating `info.circle` button below refresh button |

### List View

| Element | Unselected | Selected |
|---------|------------|----------|
| Row background | Default | Orange 10% opacity |
| Left indicators | None | `info.circle` button + `checkmark.circle.fill` icon |
| Row content | Standard | Same content, highlighted background |

## Interaction Flow

```
User taps flight (map or list)
  → viewModel.selectFlight(flight)
    → If same flight: deselect (toggle off)
    → If different flight: deselect old, select new, fetch trail
    → UI updates: highlights, trails, buttons

User taps empty map space
  → viewModel.selectFlight(nil)
    → Deselect current flight, hide trail

User taps info button
  → showDetail = true
    → Sheet opens with FlightDetailView
```

## Edge Cases

- If the historical API call fails, the accumulated trail is still shown
- Rapid selection/deselection is handled gracefully by the ViewModel's toggle logic
- Selection is cleared when the app stops tracking (trails dictionary is emptied)
- On iPad split view, selecting in the list automatically highlights on the map and vice versa
