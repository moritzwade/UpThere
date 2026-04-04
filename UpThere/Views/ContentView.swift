import SwiftUI

/// Adaptive content view - split view on iPad, tab view on iPhone
struct ContentView: View {
    @State private var viewModel = UpThereViewModel()
    @State private var showDetail = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Split view with list and map
                NavigationSplitView {
                    FlightListView(
                        viewModel: viewModel,
                        onFlightTapped: { viewModel.selectFlight($0) },
                        showDetail: $showDetail
                    )
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
                } detail: {
                    FlightMapView(
                        viewModel: viewModel,
                        onFlightTapped: { viewModel.selectFlight($0) },
                        showDetail: $showDetail
                    )
                }
            } else {
                // iPhone: Tab-based navigation
                TabView {
                    FlightMapView(
                        viewModel: viewModel,
                        onFlightTapped: { viewModel.selectFlight($0) },
                        showDetail: $showDetail
                    )
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    
                    FlightListView(
                        viewModel: viewModel,
                        onFlightTapped: { viewModel.selectFlight($0) },
                        showDetail: $showDetail
                    )
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
        .sheet(isPresented: $showDetail) {
            if let flight = viewModel.selectedFlight {
                FlightDetailView(flight: flight, viewModel: viewModel)
            }
        }
    }
}
