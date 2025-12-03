import Foundation

/// A location for weather queries.
public enum Location: Sendable, Equatable, Hashable {
    /// A location specified by latitude and longitude coordinates.
    case coordinates(latitude: Double, longitude: Double)

    /// A location specified by city name.
    case city(String)

    /**
     Whether this location is likely within the United States.

     Used to determine if NWS API should be attempted first.
     */
    public var isLikelyUS: Bool {
        switch self {
        case .coordinates(let lat, let lon):
            return USRegion.contains(latitude: lat, longitude: lon)
        case .city(let name):
            return USState.isUSCity(name)
        }
    }
}

// MARK: - US Region Boundaries

/// Geographic regions of the United States.
public enum USRegion: CaseIterable, Sendable {
    case contiguousUS
    case alaska
    case hawaii
    case caribbean  // Puerto Rico & US Virgin Islands

    /// The latitude range for this region.
    public var latitudeRange: ClosedRange<Double> {
        switch self {
        case .contiguousUS: return 24.5...49.5
        case .alaska: return 51.0...71.5
        case .hawaii: return 18.5...22.5
        case .caribbean: return 17.5...18.6
        }
    }

    /// The longitude range for this region.
    public var longitudeRange: ClosedRange<Double> {
        switch self {
        case .contiguousUS: return -125.0...(-66.0)
        case .alaska: return -180.0...(-129.0)
        case .hawaii: return -160.5...(-154.5)
        case .caribbean: return -68.0...(-64.5)
        }
    }

    /// Checks if the given coordinates fall within this region.
    public func contains(latitude: Double, longitude: Double) -> Bool {
        latitudeRange.contains(latitude) && longitudeRange.contains(longitude)
    }

    /// Checks if the given coordinates fall within any US region.
    public static func contains(latitude: Double, longitude: Double) -> Bool {
        allCases.contains { $0.contains(latitude: latitude, longitude: longitude) }
    }
}

// MARK: - US State Abbreviations

/// US state abbreviations for city name detection.
public enum USState: String, CaseIterable, Sendable {
    case alabama = "al"
    case alaska = "ak"
    case arizona = "az"
    case arkansas = "ar"
    case california = "ca"
    case colorado = "co"
    case connecticut = "ct"
    case delaware = "de"
    case florida = "fl"
    case georgia = "ga"
    case hawaii = "hi"
    case idaho = "id"
    case illinois = "il"
    case indiana = "in"
    case iowa = "ia"
    case kansas = "ks"
    case kentucky = "ky"
    case louisiana = "la"
    case maine = "me"
    case maryland = "md"
    case massachusetts = "ma"
    case michigan = "mi"
    case minnesota = "mn"
    case mississippi = "ms"
    case missouri = "mo"
    case montana = "mt"
    case nebraska = "ne"
    case nevada = "nv"
    case newHampshire = "nh"
    case newJersey = "nj"
    case newMexico = "nm"
    case newYork = "ny"
    case northCarolina = "nc"
    case northDakota = "nd"
    case ohio = "oh"
    case oklahoma = "ok"
    case oregon = "or"
    case pennsylvania = "pa"
    case rhodeIsland = "ri"
    case southCarolina = "sc"
    case southDakota = "sd"
    case tennessee = "tn"
    case texas = "tx"
    case utah = "ut"
    case vermont = "vt"
    case virginia = "va"
    case washington = "wa"
    case westVirginia = "wv"
    case wisconsin = "wi"
    case wyoming = "wy"
    case districtOfColumbia = "dc"
    case puertoRico = "pr"

    /// Checks if a city name suggests a US location.
    public static func isUSCity(_ name: String) -> Bool {
        let lower = name.lowercased()

        // Check for explicit US indicators
        if lower.contains(", us") || lower.contains(", usa") || lower.contains("united states") {
            return true
        }

        // Check for state abbreviations (e.g., "Seattle, WA")
        return allCases.contains { lower.hasSuffix(", \($0.rawValue)") }
    }
}
