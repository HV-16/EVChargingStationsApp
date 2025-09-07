//
//  NetworkClient.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation

// MARK: - NetworkMethod

/// Supported HTTP methods for this app.
/// Currently this app only requires `GET`, but the enum is kept open for future expansion.
public enum NetworkMethod: String {
    case get = "GET"
}

// MARK: - NetworkRequest

/// A lightweight descriptor for an HTTP request.
/// Contains the destination URL, HTTP method, optional headers and optional body data.
///
/// Use this to describe what you want to fetch. The `NetworkClient` converts this into a `URLRequest`.
public struct NetworkRequest {
    public let url: URL
    public let method: NetworkMethod
    public let headers: [String: String]?
    public let body: Data?
    
    /// Create a new NetworkRequest.
    /// - Parameters:
    ///   - url: The URL to call.
    ///   - method: The HTTP method to use (default `GET` if you add default later).
    ///   - headers: Optional HTTP headers.
    ///   - body: Optional HTTP body data (for POST/PUT etc).
    public init(
        url: URL,
        method: NetworkMethod,
        headers: [String : String]? = nil,
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

// MARK: - NetworkError

/// Errors returned by the network layer. Conforms to `LocalizedError` to provide readable descriptions.
public enum NetworkError: Error, LocalizedError {
    /// Response was not an `HTTPURLResponse` as expected.
    case invalidResponse
    /// Non-2xx HTTP response.
    case httpError(statusCode: Int, data: Data?)
    /// Decoding of model failed.
    case decodingError(Error)
    /// Underlying URL error (connectivity, DNS, etc).
    case urlError(URLError)
    /// Task was cancelled.
    case cancelled
    /// Any other unknown error.
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .httpError(let code, _): return "HTTP error with status code \(code)."
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .urlError(let error): return "URL error: \(error.localizedDescription)"
        case .cancelled: return "Request was cancelled."
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - NetworkClientProtocol

/// Public protocol for the network client used by ViewModels/Services.
/// Keeping a protocol makes the client easy to mock or replace in tests.
public protocol NetworkClientProtocol {
    /// Perform a request and decode the returned JSON into the provided `Decodable` type.
    /// - Parameters:
    ///   - request: A `NetworkRequest` describing the API call.
    ///   - type: The `Decodable` type to decode from the response body.
    /// - Returns: The decoded model instance.
    func request<T: Decodable>(_ request: NetworkRequest, as type: T.Type) async throws -> T
}

// MARK: - NetworkRequestBuilder

/// Small helper to convert a `NetworkRequest` into `URLRequest`.
/// Keeps URLRequest construction in one place to avoid duplication.
public struct NetworkRequestBuilder {
    /// Build a `URLRequest` from a `NetworkRequest`.
    /// - Parameters:
    ///   - networkRequest: Descriptor containing URL, method, headers and body.
    ///   - timeout: Request timeout interval in seconds (default 30).
    /// - Returns: Configured `URLRequest`.
    public static func makeRequest(from networkRequest: NetworkRequest, timeout: TimeInterval = 30) -> URLRequest {
        var request = URLRequest(url: networkRequest.url, timeoutInterval: timeout)
        request.httpMethod = networkRequest.method.rawValue
        request.httpBody = networkRequest.body
        if let headers = networkRequest.headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
    
    /// Encode an `Encodable` model as JSON data for request bodies.
    /// - Parameters:
    ///   - encodable: The encodable model to serialize.
    ///   - encoder: Optional `JSONEncoder` instance to use.
    /// - Returns: Encoded `Data`.
    public static func jsonBody<T: Encodable>(_ encodable: T, encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(encodable)
    }
}

// MARK: - NetworkClient

/// Concrete implementation of `NetworkClientProtocol` using `URLSession`.
/// - Characteristics:
///   - Uses Swift concurrency (`async/await`).
///   - Decodes responses using the injected `JSONDecoder`.
///   - Propagates rich `NetworkError` cases for ViewModel handling.
///   - Designed to be simple and easy to test via `URLSession` injection (use `URLProtocol` in tests).
public final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let requestTimeout: TimeInterval
    
    /// Designated initializer.
    /// - Parameters:
    ///   - session: The `URLSession` used to perform requests. Inject a custom session in tests.
    ///   - decoder: `JSONDecoder` used to decode JSON responses.
    ///   - requestTimeout: Per-request timeout interval in seconds.
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        requestTimeout: TimeInterval = 30
    ) {
        self.session = session
        self.decoder = decoder
        self.requestTimeout = requestTimeout
    }
    
    // MARK: Public API
    
    /// Perform a request and decode the response into the requested type.
    /// - Parameters:
    ///   - request: `NetworkRequest` describing the API call.
    ///   - type: `Decodable` type to map the response to.
    /// - Returns: Decoded model of type `T`.
    public func request<T: Decodable>(_ request: NetworkRequest, as type: T.Type) async throws -> T {
        let data = try await requestData(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: Internal helpers
    
    /// Perform the network call and return raw response `Data`.
    /// - Parameter request: `NetworkRequest` descriptor.
    /// - Returns: Response `Data`.
    private func requestData(_ request: NetworkRequest) async throws -> Data {
        let urlRequest = NetworkRequestBuilder.makeRequest(from: request, timeout: requestTimeout)
        if Task.isCancelled { throw NetworkError.cancelled }
        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            switch http.statusCode {
            case 200...299:
                return data
            default:
                throw NetworkError.httpError(statusCode: http.statusCode, data: data)
            }
        } catch let urlErr as URLError {
            throw NetworkError.urlError(urlErr)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
