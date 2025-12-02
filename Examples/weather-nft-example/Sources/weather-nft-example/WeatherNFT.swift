import Foundation
import Algorand
import Mint
import Pinata
import Weather
import SVG

// MARK: - Pinata Pinning Provider

/// Adapts swift-pinata to the IPFSPinningProvider protocol.
public actor PinataPinningProvider: IPFSPinningProvider {
    private let pinata: Pinata

    public init(pinata: Pinata) {
        self.pinata = pinata
    }

    public func pinJSON(_ metadata: ARC3Metadata) async throws -> CID {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(metadata)

        let file = try await pinata.upload(data: data, name: "metadata.json", network: .public)
        return try CID(file.cid)
    }

    public func pinFile(data: Data, name: String, mimeType: String) async throws -> CID {
        let file = try await pinata.upload(data: data, name: name, network: .public)
        return try CID(file.cid)
    }

    public func unpin(_ cid: CID) async throws {
        // Pinata doesn't have a direct unpin by CID in the new API
        // Would need to look up file ID first
    }

    public nonisolated func fetchJSON<T: Decodable>(_ cid: CID, as type: T.Type) async throws -> T {
        try await fetchJSON(cid, as: type, gateway: "https://ipfs.io")
    }
}

// MARK: - Weather NFT Actor

/// Orchestrates weather data fetching and ARC-19 NFT management.
///
/// This actor demonstrates a dynamic NFT that updates its metadata
/// based on real-time weather conditions.
///
/// Example usage:
///
/// ```swift
/// let weatherNFT = try await WeatherNFT(
///     location: .city("Seattle, WA"),
///     pinataJWT: "...",
///     algodURL: "https://testnet-api.algonode.cloud",
///     mnemonic: "..."
/// )
///
/// // Create the NFT
/// let assetID = try await weatherNFT.mint()
///
/// // Update with latest weather
/// try await weatherNFT.update()
/// ```
public actor WeatherNFT {
    /// The location to track weather for.
    public let location: Location

    /// The weather client.
    private let weather: Weather

    /// The IPFS pinning provider.
    private let pinningProvider: PinataPinningProvider

    /// The NFT minter.
    private let minter: Minter

    /// The account for signing transactions.
    private let account: Account

    /// The current asset ID (nil if not yet minted).
    private var assetID: UInt64?

    /// Creates a new WeatherNFT manager.
    ///
    /// - Parameters:
    ///   - location: The location to track weather for.
    ///   - userAgent: User-Agent for NWS API.
    ///   - pinataJWT: Pinata JWT for IPFS pinning.
    ///   - pinataGateway: Optional Pinata gateway domain.
    ///   - algodURL: Algorand node URL.
    ///   - algodToken: Optional Algorand node API token.
    ///   - mnemonic: Account mnemonic for signing.
    public init(
        location: Location,
        userAgent: String,
        pinataJWT: String,
        pinataGateway: String? = nil,
        algodURL: String,
        algodToken: String? = nil,
        mnemonic: String
    ) throws {
        self.location = location

        // Initialize weather client
        self.weather = Weather(userAgent: userAgent)

        // Initialize Pinata
        let pinata = Pinata(jwt: pinataJWT, gatewayDomain: pinataGateway)
        self.pinningProvider = PinataPinningProvider(pinata: pinata)

        // Initialize Algorand account
        self.account = try Account(mnemonic: mnemonic)

        // Initialize minter
        let minterConfig = try MinterConfiguration(
            algodURL: algodURL,
            algodToken: algodToken
        )
        self.minter = Minter(configuration: minterConfig)
    }

    /// Creates a new WeatherNFT with an existing asset ID.
    ///
    /// Use this to manage an already-minted NFT.
    public init(
        assetID: UInt64,
        location: Location,
        userAgent: String,
        pinataJWT: String,
        pinataGateway: String? = nil,
        algodURL: String,
        algodToken: String? = nil,
        mnemonic: String
    ) throws {
        self.assetID = assetID
        self.location = location
        self.weather = Weather(userAgent: userAgent)

        let pinata = Pinata(jwt: pinataJWT, gatewayDomain: pinataGateway)
        self.pinningProvider = PinataPinningProvider(pinata: pinata)
        self.account = try Account(mnemonic: mnemonic)

        let minterConfig = try MinterConfiguration(
            algodURL: algodURL,
            algodToken: algodToken
        )
        self.minter = Minter(configuration: minterConfig)
    }

    // MARK: - Public API

    /// Fetches current weather for the configured location.
    public func fetchWeather() async throws -> CurrentWeather {
        try await weather.current(at: location)
    }

    /// Mints a new Weather NFT with current conditions.
    ///
    /// - Parameters:
    ///   - unitName: Asset unit name (max 8 chars). Defaults to "WEATHER".
    ///   - assetName: Asset name (max 32 chars). Defaults to location-based name.
    ///   - svgConfig: Configuration for SVG image generation.
    /// - Returns: The created asset ID.
    public func mint(
        unitName: String = "WEATHER",
        assetName: String? = nil,
        svgConfig: WeatherSVGConfig = .default
    ) async throws -> UInt64 {
        guard assetID == nil else {
            throw WeatherNFTError.alreadyMinted(assetID!)
        }

        // Fetch current weather
        let currentWeather = try await fetchWeather()

        // Generate SVG image
        let svg = WeatherSVGGenerator.generate(from: currentWeather, config: svgConfig)
        let svgData = WeatherSVGGenerator.toData(svg)

        // Pin SVG to IPFS
        let imageCID = try await pinningProvider.pinFile(
            data: svgData,
            name: "weather.svg",
            mimeType: "image/svg+xml"
        )

        print("Pinned SVG image: \(imageCID.value)")

        // Build metadata with image
        let metadata = WeatherMetadata.build(
            from: currentWeather,
            imageCID: imageCID.value,
            imageMimetype: "image/svg+xml"
        )

        // Derive asset name from location if not provided
        let name = assetName ?? "Weather: \(currentWeather.location.name ?? "Unknown")"

        // Mint the NFT
        let result = try await minter.mintARC19WithPinning(
            account: account,
            metadata: metadata,
            pinningProvider: pinningProvider,
            unitName: unitName,
            assetName: String(name.prefix(32))
        )

        self.assetID = result.assetID

        print("Minted Weather NFT!")
        print("  Asset ID: \(result.assetID)")
        print("  Transaction: \(result.transactionID)")
        if let reserve = result.reserveAddress {
            print("  Reserve: \(reserve)")
        }

        return result.assetID
    }

    /// Updates the NFT metadata with current weather conditions.
    ///
    /// - Parameter svgConfig: Configuration for SVG image generation.
    /// - Returns: The update transaction ID.
    public func update(svgConfig: WeatherSVGConfig = .default) async throws -> String {
        guard let assetID else {
            throw WeatherNFTError.notMinted
        }

        // Fetch current weather
        let currentWeather = try await fetchWeather()

        // Generate new SVG image
        let svg = WeatherSVGGenerator.generate(from: currentWeather, config: svgConfig)
        let svgData = WeatherSVGGenerator.toData(svg)

        // Pin new SVG to IPFS
        let imageCID = try await pinningProvider.pinFile(
            data: svgData,
            name: "weather-\(Int(Date().timeIntervalSince1970)).svg",
            mimeType: "image/svg+xml"
        )

        print("Pinned updated SVG image: \(imageCID.value)")

        // Build new metadata with image
        let metadata = WeatherMetadata.build(
            from: currentWeather,
            imageCID: imageCID.value,
            imageMimetype: "image/svg+xml"
        )

        // Update the NFT
        let txID = try await minter.updateARC19WithPinning(
            account: account,
            assetID: assetID,
            newMetadata: metadata,
            pinningProvider: pinningProvider
        )

        print("Updated Weather NFT!")
        print("  Asset ID: \(assetID)")
        print("  Transaction: \(txID)")
        print("  Temperature: \(currentWeather.temperature.fahrenheit)°F")
        print("  Condition: \(currentWeather.conditionDescription)")

        return txID
    }

    /// Gets the current asset ID if minted.
    public func getAssetID() -> UInt64? {
        assetID
    }

    /// Gets the account address.
    public func getAddress() -> Address {
        account.address
    }
}

// MARK: - Errors

/// Errors specific to WeatherNFT operations.
public enum WeatherNFTError: Error, CustomStringConvertible {
    case notMinted
    case alreadyMinted(UInt64)
    case invalidConfiguration(String)

    public var description: String {
        switch self {
        case .notMinted:
            return "NFT has not been minted yet"
        case .alreadyMinted(let id):
            return "NFT already minted with asset ID: \(id)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
