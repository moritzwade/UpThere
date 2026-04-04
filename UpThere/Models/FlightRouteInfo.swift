import Foundation

/// Route information for a flight, fetched from AviationStack API
struct FlightRouteInfo: Equatable {
    /// Airline name (e.g., "United Airlines")
    let airlineName: String?
    
    /// Airline IATA code (e.g., "UA")
    let airlineIata: String?
    
    /// Airline ICAO code (e.g., "UAL")
    let airlineIcao: String?
    
    /// Departure airport ICAO (e.g., "KLAX")
    let departureAirportIcao: String?
    
    /// Departure airport IATA (e.g., "LAX")
    let departureAirportIata: String?
    
    /// Departure airport full name
    let departureAirportName: String?
    
    /// Arrival airport ICAO (e.g., "KBOS")
    let arrivalAirportIcao: String?
    
    /// Arrival airport IATA (e.g., "BOS")
    let arrivalAirportIata: String?
    
    /// Arrival airport full name
    let arrivalAirportName: String?
    
    /// Scheduled departure time
    let scheduledDeparture: Date?
    
    /// Estimated departure time
    let estimatedDeparture: Date?
    
    /// Scheduled arrival time
    let scheduledArrival: Date?
    
    /// Estimated arrival time
    let estimatedArrival: Date?
    
    /// Flight status (e.g., "active", "landed", "scheduled")
    let flightStatus: String?
    
    // MARK: - Computed Properties
    
    /// URL for the airline logo from kiwi.com
    var logoURL: URL? {
        guard let iata = airlineIata, !iata.isEmpty else { return nil }
        return URL(string: "https://images.kiwi.com/airlines/64/\(iata).png")
    }
    
    /// Formatted route string (e.g., "LAX → BOS")
    var formattedRoute: String? {
        guard let from = departureAirportIata, let to = arrivalAirportIata else { return nil }
        return "\(from) → \(to)"
    }
    
    /// Formatted airline display (e.g., "United Airlines (UAL)")
    var formattedAirline: String? {
        var parts: [String] = []
        if let name = airlineName { parts.append(name) }
        if let icao = airlineIcao { parts.append("(\(icao))") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
    
    /// Whether we have any meaningful route data
    var hasRouteData: Bool {
        departureAirportIata != nil || arrivalAirportIata != nil || airlineName != nil
    }
}

// MARK: - AviationStack API Response Parsing

extension FlightRouteInfo {
    /// Parse from AviationStack API response data
    static func parse(from data: Data) throws -> FlightRouteInfo? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let flights = json["data"] as? [[String: Any]],
              let flightData = flights.first else {
            return nil
        }
        
        // Parse airline info
        let airline = flightData["airline"] as? [String: Any]
        let airlineName = airline?["name"] as? String
        let airlineIata = airline?["iata"] as? String
        let airlineIcao = airline?["icao"] as? String
        
        // Parse departure info
        let departure = flightData["departure"] as? [String: Any]
        let depAirportIcao = departure?["icao"] as? String
        let depAirportIata = departure?["iata"] as? String
        let depAirportName = departure?["airport"] as? String
        let scheduledDep = (departure?["scheduled"] as? String).flatMap { Self.isoDateFormatter.date(from: $0) }
        let estimatedDep = (departure?["estimated"] as? String).flatMap { Self.isoDateFormatter.date(from: $0) }
        
        // Parse arrival info
        let arrival = flightData["arrival"] as? [String: Any]
        let arrAirportIcao = arrival?["icao"] as? String
        let arrAirportIata = arrival?["iata"] as? String
        let arrAirportName = arrival?["airport"] as? String
        let scheduledArr = (arrival?["scheduled"] as? String).flatMap { Self.isoDateFormatter.date(from: $0) }
        let estimatedArr = (arrival?["estimated"] as? String).flatMap { Self.isoDateFormatter.date(from: $0) }
        
        // Parse flight status
        let flightStatus = flightData["flight_status"] as? String
        
        return FlightRouteInfo(
            airlineName: airlineName,
            airlineIata: airlineIata,
            airlineIcao: airlineIcao,
            departureAirportIcao: depAirportIcao,
            departureAirportIata: depAirportIata,
            departureAirportName: depAirportName,
            arrivalAirportIcao: arrAirportIcao,
            arrivalAirportIata: arrAirportIata,
            arrivalAirportName: arrAirportName,
            scheduledDeparture: scheduledDep,
            estimatedDeparture: estimatedDep,
            scheduledArrival: scheduledArr,
            estimatedArrival: estimatedArr,
            flightStatus: flightStatus
        )
    }
    
    /// ISO 8601 date formatter for AviationStack timestamps
    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - Display Helpers

extension FlightRouteInfo {
    /// Human-readable flight status
    var displayStatus: String? {
        guard let status = flightStatus else { return nil }
        switch status.lowercased() {
        case "active", "en-route", "en route":
            return "En Route"
        case "landed":
            return "Landed"
        case "scheduled":
            return "Scheduled"
        case "cancelled":
            return "Cancelled"
        case "diverted":
            return "Diverted"
        case "incidents", "incident":
            return "Incident"
        default:
            return status.capitalized
        }
    }
    
    /// Status color for display
    var statusColor: String {
        guard let status = flightStatus?.lowercased() else { return "gray" }
        switch status {
        case "active", "en-route", "en route":
            return "green"
        case "landed":
            return "blue"
        case "cancelled":
            return "red"
        case "diverted":
            return "orange"
        default:
            return "gray"
        }
    }
}
