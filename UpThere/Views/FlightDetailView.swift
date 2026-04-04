import SwiftUI
import MapKit

/// Detail view shown when a flight is selected
struct FlightDetailView: View {
    let flight: Flight
    @Bindable var viewModel: UpThereViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView
                    
                    // Trail map
                    if let trail = viewModel.selectedFlightTrail, trail.isValid {
                        trailMapView(trail: trail)
                    } else if viewModel.isLoadingTrail {
                        HStack {
                            Spacer()
                            ProgressView("Loading flight trail...")
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Route info section (NEW)
                    routeSection
                    
                    Divider()
                    
                    // Info
                    Group {
                        Text("Flight Information").font(.headline)
                        HStack {
                            Text("Callsign:")
                            Spacer()
                            Text(flight.formattedCallsign).fontWeight(.medium)
                        }
                        HStack {
                            Text("Aircraft ID:")
                            Spacer()
                            Text(flight.id).fontWeight(.medium)
                        }
                        HStack {
                            Text("Country:")
                            Spacer()
                            Text(flight.originCountry).fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Position
                    Group {
                        Text("Position").font(.headline)
                        if let altitude = flight.altitudeFeet {
                            HStack {
                                Text("Altitude:")
                                Spacer()
                                Text("\(Int(altitude).formatted()) ft").fontWeight(.medium)
                            }
                        }
                        if let speed = flight.speedKnots {
                            HStack {
                                Text("Speed:")
                                Spacer()
                                Text("\(Int(speed)) knots").fontWeight(.medium)
                            }
                        }
                        if let track = flight.trueTrack {
                            HStack {
                                Text("Heading:")
                                Spacer()
                                Text("\(Int(track))°").fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Coordinates
                    Group {
                        Text("Coordinates").font(.headline)
                        if let lat = flight.latitude {
                            HStack {
                                Text("Latitude:")
                                Spacer()
                                Text(String(format: "%.6f°", lat)).fontWeight(.medium)
                            }
                        }
                        if let lon = flight.longitude {
                            HStack {
                                Text("Longitude:")
                                Spacer()
                                Text(String(format: "%.6f°", lon)).fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Flight Details")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Airline Info Helpers
    
    /// Airline info from local database (always available if callsign matches)
    private var localAirlineInfo: AirlineInfo? {
        guard let designator = flight.airlineDesignator else { return nil }
        return AirlineDatabase.lookup(icao: designator)
    }
    
    /// Logo URL — prefer API data, fall back to local database
    private var logoURL: URL? {
        // First try from API route data
        if let url = viewModel.selectedFlightRoute?.logoURL {
            return url
        }
        // Fall back to local database
        if let info = localAirlineInfo {
            return URL(string: "https://images.kiwi.com/airlines/64/\(info.iata).png")
        }
        return nil
    }
    
    /// Airline display name — prefer API data, fall back to local database
    private var airlineDisplayName: String? {
        if let name = viewModel.selectedFlightRoute?.formattedAirline {
            return name
        }
        if let info = localAirlineInfo {
            return "\(info.name) (\(info.icao))"
        }
        return nil
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Airline logo (from API or local database)
                    if let url = logoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            case .failure, .empty:
                                airlineDesignatorBadge
                            @unknown default:
                                airlineDesignatorBadge
                            }
                        }
                    } else {
                        airlineDesignatorBadge
                    }
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(flight.trueTrack ?? 0))
                }
                
                Text(flight.formattedCallsign)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Route display (e.g., "LAX → BOS")
                if let route = viewModel.selectedFlightRoute?.formattedRoute {
                    Text(route)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Flight status badge
                if let status = viewModel.selectedFlightRoute?.displayStatus {
                    Text(status)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }
    
    /// Airline designator badge when logo is unavailable
    private var airlineDesignatorBadge: some View {
        Group {
            if let designator = flight.airlineDesignator {
                Text(designator)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange.opacity(0.5))
            }
        }
    }
    
    /// Status color based on route info
    private var statusColor: Color {
        guard let status = viewModel.selectedFlightRoute?.flightStatus?.lowercased() else { return .gray }
        switch status {
        case "active", "en-route", "en route":
            return .green
        case "landed":
            return .blue
        case "cancelled":
            return .red
        case "diverted":
            return .orange
        default:
            return .gray
        }
    }
    
    // MARK: - Route Section
    
    @ViewBuilder
    private var routeSection: some View {
        let route = viewModel.selectedFlightRoute
        let hasAirportData = route?.departureAirportIata != nil || route?.arrivalAirportIata != nil
        let hasAirlineData = airlineDisplayName != nil
        
        if hasAirlineData || hasAirportData || viewModel.isLoadingRoute {
            Group {
                Text("Route").font(.headline)
                
                // Airline — from API or local database
                if let airline = airlineDisplayName {
                    HStack {
                        Text("Airline:")
                        Spacer()
                        Text(airline).fontWeight(.medium)
                    }
                }
                
                // Origin airport (from API)
                if let depAirport = route?.departureAirportIata {
                    HStack {
                        Text("Origin:")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(depAirport).fontWeight(.medium)
                            if let name = route?.departureAirportName {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Destination airport (from API)
                if let arrAirport = route?.arrivalAirportIata {
                    HStack {
                        Text("Destination:")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(arrAirport).fontWeight(.medium)
                            if let name = route?.arrivalAirportName {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Estimated/Scheduled arrival (from API)
                if let estimatedArrival = route?.estimatedArrival {
                    HStack {
                        Text("Est. Arrival:")
                        Spacer()
                        Text(estimatedArrival, style: .time).fontWeight(.medium)
                    }
                } else if let scheduledArrival = route?.scheduledArrival {
                    HStack {
                        Text("Scheduled Arrival:")
                        Spacer()
                        Text(scheduledArrival, style: .time).fontWeight(.medium)
                    }
                }
                
                // Loading indicator for route data
                if viewModel.isLoadingRoute && route == nil {
                    HStack {
                        Spacer()
                        ProgressView("Loading route info...")
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Trail Map View
    
    @ViewBuilder
    private func trailMapView(trail: FlightTrail) -> some View {
        Group {
            Map(position: $cameraPosition) {
                // Trail polyline
                MapPolyline(coordinates: trail.coordinates)
                    .stroke(Color.orange, lineWidth: 3)
                
                // Current position marker
                if let currentCoord = flight.coordinate {
                    Annotation(flight.formattedCallsign, coordinate: currentCoord) {
                        Image(systemName: "airplane")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(flight.trueTrack ?? 0))
                            .padding(8)
                            .background(Color.orange.opacity(0.3), in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                            }
                    }
                }
                
                // Trail start marker
                if let startCoord = trail.positions.first?.coordinate {
                    Annotation("Start", coordinate: startCoord) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                // Set camera to show the full trail
                if let coordinateRegion = trail.coordinateRegion {
                    cameraPosition = .region(coordinateRegion)
                }
            }
        }
        .padding(.horizontal)
    }
}
