import Foundation

/// Environment-based configuration for the Weather NFT example.
enum Config {
    // MARK: - Weather

    /// User-Agent for NWS API requests.
    static var weatherUserAgent: String {
        env("WEATHER_USER_AGENT") ?? "(WeatherNFT, weather-nft@example.com)"
    }

    // MARK: - Pinata (IPFS)

    /// Pinata JWT token for authentication.
    static var pinataJWT: String {
        env("PINATA_JWT") ?? ""
    }

    /// Pinata gateway domain for accessing files.
    static var pinataGateway: String? {
        env("PINATA_GATEWAY")
    }

    // MARK: - Algorand

    /// Algod API URL.
    static var algodURL: String {
        env("ALGOD_URL") ?? "https://testnet-api.algonode.cloud"
    }

    /// Algod API token (optional for public nodes).
    static var algodToken: String? {
        env("ALGOD_TOKEN")
    }

    /// Account mnemonic for signing transactions.
    static var accountMnemonic: String {
        env("ACCOUNT_MNEMONIC") ?? ""
    }

    // MARK: - Private

    private static func env(_ key: String) -> String? {
        let value = ProcessInfo.processInfo.environment[key]
        return value?.isEmpty == true ? nil : value
    }
}
