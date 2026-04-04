# UpThere Requirements

This directory contains the requirements for the UpThere flight tracking application. Each requirement is documented as a Markdown file with structured YAML frontmatter for both human readability and agent parsing.

## Directory Structure

```
Requirements/
├── README.md                       ← This file
├── core/                           ← System requirements (SYSREQ-*)
│   ├── SYSREQ-001-flight-tracking.md
│   ├── SYSREQ-002-location-services.md
│   ├── SYSREQ-003-authentication.md
│   ├── SYSREQ-004-auto-refresh.md
│   ├── SYSREQ-005-manual-refresh.md
│   └── SYSREQ-006-error-handling.md
├── ui/                             ← User interface requirements (UIREQ-*)
│   ├── UIREQ-001-flight-list-view.md
│   ├── UIREQ-002-flight-map-view.md
│   ├── UIREQ-003-flight-detail-view.md
│   └── UIREQ-004-adaptive-layout.md
└── non-functional/                 ← Non-functional requirements (NFREQ-*)
    ├── NFREQ-001-performance.md
    ├── NFREQ-002-logging.md
    ├── NFREQ-003-platform-compatibility.md
    └── NFREQ-004-test-coverage.md
```

## Requirement File Format

Each requirement file uses Markdown with YAML frontmatter:

```yaml
---
id: SYSREQ-001
title: Short descriptive title
priority: high | medium | low
type: feature | non-functional | constraint
status: implemented | proposed | deprecated
tags: [tag1, tag2]
scenarios:
  - id: SC-SYSREQ-001-01
    name: Short scenario name
    given: Precondition
    when: Action
    then: Expected result
---
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier with type prefix: `SYSREQ-NNN`, `UIREQ-NNN`, or `NFREQ-NNN` |
| `title` | Yes | Short descriptive title |
| `priority` | Yes | `high`, `medium`, or `low` |
| `type` | Yes | `feature`, `non-functional`, or `constraint` |
| `status` | Yes | `implemented`, `proposed`, or `deprecated` |
| `tags` | Yes | Array of descriptive tags |
| `scenarios` | Yes | Array of Given/When/Then test scenarios (see below) |

### Scenario Format (Given/When/Then)

Scenarios are structured for future automated UI test generation. Each scenario has:

| Field | Description |
|-------|-------------|
| `id` | Unique identifier in format `SC-{REQID}-{NN}` (e.g., `SC-SYSREQ-001-01`) |
| `name` | Short human-readable name |
| `given` | Precondition(s) that must be true |
| `when` | User or system action |
| `then` | Expected observable result |

## Requirements Index

### System Requirements (SYSREQ-*)

| ID | Title | Priority | Status |
|----|-------|----------|--------|
| [SYSREQ-001](core/SYSREQ-001-flight-tracking.md) | Real-Time Flight Tracking | high | implemented |
| [SYSREQ-002](core/SYSREQ-002-location-services.md) | Location Services | high | implemented |
| [SYSREQ-003](core/SYSREQ-003-authentication.md) | OAuth2 Authentication | high | implemented |
| [SYSREQ-004](core/SYSREQ-004-auto-refresh.md) | Auto-Refresh | medium | implemented |
| [SYSREQ-005](core/SYSREQ-005-manual-refresh.md) | Manual Refresh | medium | implemented |
| [SYSREQ-006](core/SYSREQ-006-error-handling.md) | Error Handling | medium | implemented |

### User Interface Requirements (UIREQ-*)

| ID | Title | Priority | Status |
|----|-------|----------|--------|
| [UIREQ-001](ui/UIREQ-001-flight-list-view.md) | Flight List View | high | implemented |
| [UIREQ-002](ui/UIREQ-002-flight-map-view.md) | Flight Map View | high | implemented |
| [UIREQ-003](ui/UIREQ-003-flight-detail-view.md) | Flight Detail View | medium | implemented |
| [UIREQ-004](ui/UIREQ-004-adaptive-layout.md) | Adaptive Layout | medium | implemented |

### Non-Functional Requirements (NFREQ-*)

| ID | Title | Priority | Status |
|----|-------|----------|--------|
| [NFREQ-001](non-functional/NFREQ-001-performance.md) | Performance | medium | implemented |
| [NFREQ-002](non-functional/NFREQ-002-logging.md) | Logging | medium | implemented |
| [NFREQ-003](non-functional/NFREQ-003-platform-compatibility.md) | Platform Compatibility | medium | implemented |
| [NFREQ-004](non-functional/NFREQ-004-test-coverage.md) | Test Coverage | medium | implemented |

## Conventions

### ID Prefixes

| Prefix | Category | Directory | Description |
|--------|----------|-----------|-------------|
| `SYSREQ-*` | System | `core/` | Core functionality, services, and business logic |
| `UIREQ-*` | User Interface | `ui/` | Screens, views, and user interactions |
| `NFREQ-*` | Non-Functional | `non-functional/` | Performance, logging, compatibility, testing |

Each prefix uses its own independent counter starting at 001.

### File Naming

Files are named `{PREFIX}-NNN-kebab-case-title.md`, matching the requirement ID and title. For example:
- `SYSREQ-001-flight-tracking.md`
- `UIREQ-003-flight-detail-view.md`
- `NFREQ-002-logging.md`

### Adding New Requirements

1. Determine the appropriate category (system, UI, non-functional)
2. Use the next available number for that prefix
3. Create the file with YAML frontmatter and Markdown body
4. Update this README's index table
5. Ensure all scenarios are testable (Given/When/Then format)

### Updating Requirements

When code changes affect an existing requirement:
1. Update the requirement file to reflect the new behavior
2. Add/update scenarios as needed
3. Update the status if the requirement changes from `implemented` to `proposed` or vice versa
