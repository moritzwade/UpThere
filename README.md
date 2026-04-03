# UpThere

Real-time airplane flight tracker for macOS and iOS.

## Features

- Live flight tracking on an interactive map
- Flight details: altitude, speed, heading, coordinates
- Automatic refresh every 5 seconds
- Adaptive UI: split view on iPad, tab view on iPhone

## Setup

### 1. OpenSky Account (optional)

For higher rate limits, create a free account at [opensky-network.org](https://opensky-network.org/) and set environment variables:

```bash
export OPENSKY_USERNAME="your_username"
export OPENSKY_PASSWORD="your_password"
```

### 2. Build

```bash
# Regenerate Xcode project
xcodegen generate

# macOS
xcodebuild -project FlightTracker.xcodeproj -target UpThereMac -configuration Debug build

# iOS (requires simulator)
xcodebuild -project FlightTracker.xcodeproj -target UpThere -sdk iphonesimulator -configuration Debug build
```

### 3. Run

```bash
# macOS
open build/Debug/UpThere.app
```

## Requirements

- macOS 14.0+ or iOS 17.0+
- Location services enabled
- OpenSky Network account (free, optional)

## Data Source

Uses the [OpenSky Network API](https://opensky-network.org/) for real-time flight data.
