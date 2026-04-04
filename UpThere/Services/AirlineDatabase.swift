import Foundation

/// Local airline database mapping ICAO codes to airline information
/// Used as a fallback when the AviationStack API is not available
enum AirlineDatabase {
    
    /// Look up airline info by ICAO code
    static func lookup(icao: String) -> AirlineInfo? {
        airlines[icao.uppercased()]
    }
    
    /// Look up airline info by IATA code
    static func lookupIata(_ iata: String) -> AirlineInfo? {
        airlinesByIata[iata.uppercased()]
    }
}

/// Airline information
struct AirlineInfo {
    let name: String
    let iata: String
    let icao: String
}

// MARK: - Airline Database

private let airlines: [String: AirlineInfo] = {
    var db = [String: AirlineInfo]()
    
    for info in airlineList {
        db[info.icao.uppercased()] = info
    }
    return db
}()

private let airlinesByIata: [String: AirlineInfo] = {
    var db = [String: AirlineInfo]()
    
    for info in airlineList {
        db[info.iata.uppercased()] = info
    }
    return db
}()

// MARK: - Airline List

private let airlineList: [AirlineInfo] = [
    // North America
    AirlineInfo(name: "United Airlines", iata: "UA", icao: "UAL"),
    AirlineInfo(name: "American Airlines", iata: "AA", icao: "AAL"),
    AirlineInfo(name: "Delta Air Lines", iata: "DL", icao: "DAL"),
    AirlineInfo(name: "Southwest Airlines", iata: "WN", icao: "SWA"),
    AirlineInfo(name: "JetBlue Airways", iata: "B6", icao: "JBU"),
    AirlineInfo(name: "Alaska Airlines", iata: "AS", icao: "ASA"),
    AirlineInfo(name: "Spirit Airlines", iata: "NK", icao: "NKS"),
    AirlineInfo(name: "Frontier Airlines", iata: "F9", icao: "FFT"),
    AirlineInfo(name: "Hawaiian Airlines", iata: "HA", icao: "HAL"),
    AirlineInfo(name: "Allegiant Air", iata: "G4", icao: "AAY"),
    AirlineInfo(name: "Air Canada", iata: "AC", icao: "ACA"),
    AirlineInfo(name: "WestJet", iata: "WS", icao: "WJA"),
    AirlineInfo(name: "Porter Airlines", iata: "PD", icao: "POE"),
    
    // Europe
    AirlineInfo(name: "Lufthansa", iata: "LH", icao: "DLH"),
    AirlineInfo(name: "British Airways", iata: "BA", icao: "BAW"),
    AirlineInfo(name: "Air France", iata: "AF", icao: "AFR"),
    AirlineInfo(name: "KLM Royal Dutch Airlines", iata: "KL", icao: "KLM"),
    AirlineInfo(name: "Scandinavian Airlines", iata: "SK", icao: "SAS"),
    AirlineInfo(name: "Iberia", iata: "IB", icao: "IBE"),
    AirlineInfo(name: "Alitalia", iata: "AZ", icao: "AZA"),
    AirlineInfo(name: "ITA Airways", iata: "AZ", icao: "ITY"),
    AirlineInfo(name: "Swiss International Air Lines", iata: "LX", icao: "SWR"),
    AirlineInfo(name: "Austrian Airlines", iata: "OS", icao: "AUA"),
    AirlineInfo(name: "Brussels Airlines", iata: "SN", icao: "BEL"),
    AirlineInfo(name: "Finnair", iata: "AY", icao: "FIN"),
    AirlineInfo(name: "TAP Air Portugal", iata: "TP", icao: "TAP"),
    AirlineInfo(name: "Ryanair", iata: "FR", icao: "RYR"),
    AirlineInfo(name: "easyJet", iata: "U2", icao: "EZY"),
    AirlineInfo(name: "Norwegian Air Shuttle", iata: "DY", icao: "NAX"),
    AirlineInfo(name: "Wizz Air", iata: "W6", icao: "WZZ"),
    AirlineInfo(name: "Eurowings", iata: "EW", icao: "EWG"),
    AirlineInfo(name: "Vueling", iata: "VY", icao: "VLG"),
    AirlineInfo(name: "Turkish Airlines", iata: "TK", icao: "THY"),
    AirlineInfo(name: "Aer Lingus", iata: "EI", icao: "EIN"),
    AirlineInfo(name: "LOT Polish Airlines", iata: "LO", icao: "LOT"),
    AirlineInfo(name: "Czech Airlines", iata: "OK", icao: "CSA"),
    AirlineInfo(name: "Air Europa", iata: "UX", icao: "AEA"),
    AirlineInfo(name: "TUI fly", iata: "X3", icao: "TUI"),
    AirlineInfo(name: "Condor", iata: "DE", icao: "CFG"),
    
    // Asia
    AirlineInfo(name: "Emirates", iata: "EK", icao: "UAE"),
    AirlineInfo(name: "Qatar Airways", iata: "QR", icao: "QTR"),
    AirlineInfo(name: "Etihad Airways", iata: "EY", icao: "ETD"),
    AirlineInfo(name: "Singapore Airlines", iata: "SQ", icao: "SIA"),
    AirlineInfo(name: "Cathay Pacific", iata: "CX", icao: "CPA"),
    AirlineInfo(name: "Japan Airlines", iata: "JL", icao: "JAL"),
    AirlineInfo(name: "All Nippon Airways", iata: "NH", icao: "ANA"),
    AirlineInfo(name: "Korean Air", iata: "KE", icao: "KAL"),
    AirlineInfo(name: "Asiana Airlines", iata: "OZ", icao: "AAR"),
    AirlineInfo(name: "China Southern Airlines", iata: "CZ", icao: "CSN"),
    AirlineInfo(name: "China Eastern Airlines", iata: "MU", icao: "CES"),
    AirlineInfo(name: "Air China", iata: "CA", icao: "CCA"),
    AirlineInfo(name: "Thai Airways", iata: "TG", icao: "THA"),
    AirlineInfo(name: "Malaysia Airlines", iata: "MH", icao: "MAS"),
    AirlineInfo(name: "Philippine Airlines", iata: "PR", icao: "PAL"),
    AirlineInfo(name: "Vietnam Airlines", iata: "VN", icao: "HVN"),
    AirlineInfo(name: "Garuda Indonesia", iata: "GA", icao: "GIA"),
    AirlineInfo(name: "IndiGo", iata: "6E", icao: "IGO"),
    AirlineInfo(name: "Air India", iata: "AI", icao: "AIC"),
    
    // Middle East & Africa
    AirlineInfo(name: "Royal Jordanian", iata: "RJ", icao: "RJA"),
    AirlineInfo(name: "El Al", iata: "LY", icao: "ELY"),
    AirlineInfo(name: "Ethiopian Airlines", iata: "ET", icao: "ETH"),
    AirlineInfo(name: "South African Airways", iata: "SA", icao: "SAA"),
    AirlineInfo(name: "EgyptAir", iata: "MS", icao: "MSR"),
    AirlineInfo(name: "Kenya Airways", iata: "KQ", icao: "KQA"),
    
    // Oceania
    AirlineInfo(name: "Qantas", iata: "QF", icao: "QFA"),
    AirlineInfo(name: "Virgin Australia", iata: "VA", icao: "VOZ"),
    AirlineInfo(name: "Jetstar Airways", iata: "JQ", icao: "JST"),
    AirlineInfo(name: "Air New Zealand", iata: "NZ", icao: "ANZ"),
    
    // Latin America
    AirlineInfo(name: "LATAM Airlines", iata: "LA", icao: "LAN"),
    AirlineInfo(name: "Gol Linhas Aereas", iata: "G3", icao: "GLO"),
    AirlineInfo(name: "Avianca", iata: "AV", icao: "AVA"),
    AirlineInfo(name: "Copa Airlines", iata: "CM", icao: "CMP"),
    AirlineInfo(name: "Aeromexico", iata: "AM", icao: "AMX"),
    AirlineInfo(name: "Azul Brazilian Airlines", iata: "AD", icao: "AZU"),
    
    // Cargo
    AirlineInfo(name: "FedEx Express", iata: "FX", icao: "FDX"),
    AirlineInfo(name: "UPS Airlines", iata: "5X", icao: "UPS"),
    AirlineInfo(name: "DHL Aviation", iata: "D0", icao: "DHK"),
]
