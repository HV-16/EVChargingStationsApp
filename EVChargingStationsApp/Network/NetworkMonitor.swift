//
//  NetworkMonitor.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import Network

/// Monitors network reachability (Wi-Fi / Cellular).
/// - Uses `NWPathMonitor` (iOS 12+).
/// - Exposes `isConnected` flag you can check before making network requests.
public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) public var isConnected: Bool = true

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}
