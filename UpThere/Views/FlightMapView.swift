import SwiftUI
import MapKit

/// Flight selection callback type
typealias FlightSelectionHandler = (Flight) -> Void

/// Map view showing flights as annotations
struct FlightMapView: View {
    @Bindable var viewModel: UpThereViewModel
    var onFlightSelected: FlightSelectionHandler?
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasInitialLocationSet = false
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // User location
                if let location = viewModel.userLocation {
                    Annotation("You", coordinate: location.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
                }
                
                // Flight markers
                ForEach(viewModel.flights) { flight in
                    if let coordinate = flight.coordinate {
                        Annotation(flight.formattedCallsign, coordinate: coordinate) {
                            FlightAnnotationView(flight: flight, isSelected: viewModel.selectedFlight?.id == flight.id)
                                .onTapGesture {
                                    onFlightSelected?(flight)
                                }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { _ in
                // Refresh flights when user pans/zooms the map
                Task {
                    await viewModel.refreshFlights()
                }
            }
            
            // Overlay controls - positioned to not overlap with map controls
            VStack {
                HStack {
                    Spacer()
                    refreshButton
                        .offset(x: 20, y: 40)
                }
                Spacer()
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }
            }
            .padding()
        }
        .navigationTitle("Flights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: viewModel.userLocation) {
            // Center on user location when first available
            if !hasInitialLocationSet, let location = viewModel.userLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 150_000,
                    longitudinalMeters: 150_000
                ))
                hasInitialLocationSet = true
            }
        }
    }
    
    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.refreshFlights()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .padding(10)
                    .background(.regularMaterial, in: Circle())
            }
        }
    }
    
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.9))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

/// Custom annotation view for flights
struct FlightAnnotationView: View {
    let flight: Flight
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: "airplane")
            .font(.title2)
            .foregroundColor(.orange)
            .rotationEffect(.degrees(flight.trueTrack ?? 0))
            .padding(8)
            .background(isSelected ? Color.orange.opacity(0.3) : Color.white.opacity(0.9), in: Circle())
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
            }
            .shadow(radius: 2)
    }
}
