import SwiftUI
import CoreLocation

/// List view showing all flights
struct FlightListView: View {
    @Bindable var viewModel: UpThereViewModel
    var onFlightSelected: FlightSelectionHandler?
    @State private var sortOrder = SortOrder.distance
    
    enum SortOrder: String, CaseIterable {
        case callsign = "Callsign"
        case altitude = "Altitude"
        case distance = "Distance"
    }
    
    var sortedFlights: [Flight] {
        let location = viewModel.userLocation ?? LocationService.defaultLocation
        
        switch sortOrder {
        case .callsign:
            return viewModel.flights.sorted { $0.callsign < $1.callsign }
        case .altitude:
            return viewModel.flights.sorted { ($0.baroAltitude ?? 0) > ($1.baroAltitude ?? 0) }
        case .distance:
            return viewModel.flights.sorted {
                ($0.distanceKm(from: location) ?? .infinity) < ($1.distanceKm(from: location) ?? .infinity)
            }
        }
    }
    
    var body: some View {
        List(sortedFlights) { flight in
            FlightRowView(flight: flight, userLocation: viewModel.userLocation)
                .contentShape(Rectangle())
                .onTapGesture {
                    onFlightSelected?(flight)
                }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshFlights()
        }
        .navigationTitle("Flights (\(viewModel.flights.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                sortMenu
            }
        }
        .overlay {
            if viewModel.flights.isEmpty && !viewModel.isLoading {
                emptyStateView
            }
        }
    }
    
    private var sortMenu: some View {
        Menu {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button {
                    sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Flights")
                .font(.title2)
                .fontWeight(.semibold)
            Text("No flights detected in your area")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Row view for a single flight in the list
struct FlightRowView: View {
    let flight: Flight
    let userLocation: CLLocation?
    
    var body: some View {
        HStack(spacing: 12) {
            // Flight icon with rotation
            Image(systemName: "airplane")
                .font(.title2)
                .foregroundColor(.orange)
                .rotationEffect(.degrees(flight.trueTrack ?? 0))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.formattedCallsign)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    if let altitude = flight.altitudeFeet {
                        Label("\(Int(altitude).formatted()) ft", systemImage: "arrow.up.and.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let speed = flight.speedKnots {
                        Label("\(Int(speed)) kts", systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let distance = flight.distanceKm(from: userLocation ?? LocationService.defaultLocation) {
                    Text("\(Int(distance)) km")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(flight.originCountry)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
