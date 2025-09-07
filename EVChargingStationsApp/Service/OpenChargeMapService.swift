//
//  OpenChargeMapService.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation

// MARK: - OpenChargeMapServiceProtocol

public protocol OpenChargeMapServiceProtocol {
    /// Fetch POIs near a geographic coordinate.
    /// - Parameters:
    ///   - latitude: Center latitude.
    ///   - longitude: Center longitude.
    ///   - distanceKm: Search radius in kilometers (default 10).
    ///   - maxResults: Maximum number of results (default 100).
    /// - Returns: Array of `ChargingStation`.
    /// - Throws: Errors thrown by the injected `NetworkClientProtocol`.
    func fetchStations(
        latitude: Double?,
        longitude: Double?,
        distanceKm: Double?,
        maxResults: Int
    ) async throws -> [ChargingStation]
}

// MARK: - OpenChargeMapService

/// Lightweight service that builds Open Charge Map POI URLs and returns decoded `[ChargingStation]`.
/// - This class is intentionally thin: it only builds URLs, creates `NetworkRequest`s and delegates
///   the network + decoding work to a `NetworkClientProtocol` instance supplied via dependency injection.
/// - The service exposes two fetch variants:
///     1. `fetchStations(latitude:longitude:...)` — location-based search (preferred when you have coordinates).
///     2. `fetchStations(maxResults:...)` — generic list without location (useful when the user denies location
///         permission or when you want a global/uncentered result).
public final class OpenChargeMapService: OpenChargeMapServiceProtocol {
    // MARK: Dependencies

    private let client: NetworkClientProtocol
    private let decoder: JSONDecoder

    // MARK: - Init

    /// Create the service.
    /// - Parameters:
    ///   - client: Concrete network client conforming to `NetworkClientProtocol`.
    public init(client: NetworkClientProtocol) {
        self.client = client
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public API

    public func fetchStations(
        latitude: Double?,
        longitude: Double?,
        distanceKm: Double?,
        maxResults: Int
    ) async throws -> [ChargingStation] {
        let url = OpenChargeMapAPI.poiURL(
            latitude: latitude,
            longitude: longitude,
            distanceKm: distanceKm,
            maxResults: maxResults
        )
        let request = NetworkRequest(url: url, method: .get)
        return try await client.request(request, as: [ChargingStation].self)
    }
}

// MARK: - OpenChargeMapAPI

/// Helper utilities for building Open Charge Map API URLs.
/// Keep URL construction centralized so query parameter naming / defaults are consistent.
public enum OpenChargeMapAPI {
    public static let base = "https://api.openchargemap.io/v3"

    /// Build a POI URL for a location-centered search.
    /// - Note: The `apiKey` parameter allows injection of a runtime key. If left `nil` a default
    ///         development key is used; replace this with secure injection in production.
    public static func poiURL(
        latitude: Double?,
        longitude: Double?,
        distanceKm: Double?,
        maxResults: Int
    ) -> URL {
        var comps = URLComponents(string: "\(base)/poi")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "key", value: "946ea481-70b9-40bf-b89f-3f3a84539f58"),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "maxresults", value: String(maxResults)),
            URLQueryItem(name: "verbose", value: "false")
        ]
        if let latitude {
            items.append(URLQueryItem(name: "latitude", value: String(latitude)))
        }
        if let longitude {
            items.append(URLQueryItem(name: "longitude", value: String(longitude)))
        }
        if let distanceKm {
            items.append(URLQueryItem(name: "distance", value: String(distanceKm)))
        }
        comps.queryItems = items
        return comps.url!
    }
}
