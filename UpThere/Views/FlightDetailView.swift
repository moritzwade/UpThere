import SwiftUI
import MapKit

/// Detail view shown when a flight is selected
struct FlightDetailView: View {
    let flight: Flight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
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
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    
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
}
