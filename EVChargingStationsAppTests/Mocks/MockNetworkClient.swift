//
//  MockNetworkClient.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
@testable import EVChargingStationsApp

// MARK: - Mock NetworkClient

final class MockNetworkClient: NetworkClientProtocol {
    var lastRequest: NetworkRequest?
    var responseData: Data?
    var error: Error?

    func request<T>(_ request: NetworkRequest, as type: T.Type) async throws -> T where T : Decodable {
        lastRequest = request
        if let error = error { throw error }
        guard let data = responseData else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    }
}
