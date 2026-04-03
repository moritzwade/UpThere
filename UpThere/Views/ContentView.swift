import SwiftUI

/// Adaptive content view - split view on iPad, tab view on iPhone
struct ContentView: View {
    @State private var viewModel = UpThereViewModel()
    @State private var selectedFlightForDetail: Flight?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Split view with list and map
                NavigationSplitView {
                    FlightListView(viewModel: viewModel, onFlightSelected: { flight in
                        selectedFlightForDetail = flight
                    })
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
                } detail: {
                    FlightMapView(viewModel: viewModel, onFlightSelected: { flight in
                        selectedFlightForDetail = flight
                    })
                }
            } else {
                // iPhone: Tab-based navigation
                TabView {
                    FlightMapView(viewModel: viewModel, onFlightSelected: { flight in
                        selectedFlightForDetail = flight
                    })
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    
                    FlightListView(viewModel: viewModel, onFlightSelected: { flight in
                        selectedFlightForDetail = flight
                    })
                    .tabItem {
                        Label("Flights", systemImage: "airplane")
                    }
                }
            }
        }
        .onAppear {
            viewModel.startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .sheet(item: $selectedFlightForDetail) { flight in
            FlightDetailView(flight: flight)
        }
    }
}
