import SwiftUI
import MapKit

/// Detail view shown when a flight is selected
struct FlightDetailView: View {
    let flight: Flight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Header with flight icon
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "airplane")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .rotationEffect(.degrees(flight.trueTrack ?? 0))
                            
                            Text(flight.formattedCallsign)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .listRowBackground(Color.orange.opacity(0.1))
                }
                
                // Callsign section
                Section("Flight Information") {
                    LabeledContent("Callsign", value: flight.formattedCallsign)
                    LabeledContent("Aircraft ID", value: flight.id.uppercased())
                    LabeledContent("Country", value: flight.originCountry)
                }
                
                // Position section
                Section("Position") {
                    if let altitude = flight.altitudeFeet {
                        LabeledContent("Altitude", value: "\(Int(altitude).formatted()) ft")
                    } else {
                        LabeledContent("Status", value: flight.onGround ? "On Ground" : "Unknown")
                    }
                    
                    if let speed = flight.speedKnots {
                        LabeledContent("Speed", value: "\(Int(speed)) knots")
                    }
                    
                    if let track = flight.trueTrack {
                        LabeledContent("Heading", value: "\(Int(track))°")
                    }
                    
                    if let verticalRate = flight.verticalRateFPM {
                        LabeledContent("Vertical Speed", value: "\(Int(verticalRate)) fpm")
                    }
                }
                
                // Coordinates section
                Section("Coordinates") {
                    if let lat = flight.latitude {
                        LabeledContent("Latitude", value: String(format: "%.6f°", lat))
                    }
                    if let lon = flight.longitude {
                        LabeledContent("Longitude", value: String(format: "%.6f°", lon))
                    }
                }
                
                // Additional info
                Section("Additional") {
                    if let squawk = flight.squawk, !squawk.isEmpty {
                        LabeledContent("Squawk", value: squawk)
                    }
                    LabeledContent("Last Update", value: formatDate(flight.lastContact))
                }
            }
            .navigationTitle("Flight Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
