# UpThere

Real-time airplane flight tracker for macOS and iOS.

## Features

- Live flight tracking on an interactive map
- Flight details: altitude, speed, heading, coordinates
- Automatic refresh every 5 seconds
- Adaptive UI: split view on iPad, tab view on iPhone

## Setup

### 1. OpenSky Account (optional)

For higher rate limits, create a free account at [opensky-network.org](https://opensky-network.org/) and create an API client:

1. Log in to your OpenSky account
2. Go to Account page
3. Create a new API client to get `client_id` and `client_secret`

Set environment variables:

```bash
export OPENSKY_CLIENT_ID="your_client_id"
export OPENSKY_CLIENT_SECRET="your_client_secret"
```

**Or add to Xcode scheme:**
1. Open project in Xcode
2. Product → Scheme → Edit Scheme
3. Select Run → Arguments tab
4. Add Environment Variables:
   - `OPENSKY_CLIENT_ID` = your_client_id
   - `OPENSKY_CLIENT_SECRET` = your_client_secret

### 2. Build

```bash
# Regenerate Xcode project
xcodegen generate

# macOS
xcodebuild -project UpThere.xcodeproj -target UpThereMac -configuration Debug build

# iOS (requires simulator)
xcodebuild -project UpThere.xcodeproj -target UpThere -sdk iphonesimulator -configuration Debug build
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
