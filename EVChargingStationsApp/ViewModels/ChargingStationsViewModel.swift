//
//  ChargingStationsViewModel.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import SwiftUI

@MainActor
public final class ChargingStationsViewModel: ObservableObject {
    // MARK: - Published properties
    @Published public private(set) var chargingStations: [ChargingStation] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var showRetryWithoutLocation: Bool = false
    @Published public var selectedStation: ChargingStation?

    // MARK: - Dependencies
    private let service: OpenChargeMapServiceProtocol

    // MARK: - Config
    public var defaultDistanceKm: Double = 20
    public var defaultMaxResults: Int = 100
    private var currentLoadTask: Task<Void, Never>?

    // MARK: - Init
    public init(service: OpenChargeMapServiceProtocol) {
        self.service = service
    }

    // MARK: - Public API

    /// Fetch charging stations from API.
    public func fetchChargingStations() {
        currentLoadTask?.cancel()

        currentLoadTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.errorMessage = nil
            self.showRetryWithoutLocation = false

            if !NetworkMonitor.shared.isConnected {
                self.errorMessage = "No internet connection."
                self.isLoading = false
                self.currentLoadTask = nil
                return
            }

            await self.getChargingStations(
                latitude: nil,
                longitude: nil,
                distance: defaultDistanceKm,
                results: defaultMaxResults
            )

            if self.chargingStations.isEmpty && self.errorMessage == nil {
                self.errorMessage = "No stations found."
            }

            self.isLoading = false
            self.currentLoadTask = nil
        }
    }

    // MARK: - Private helpers

    private func getChargingStations(
        latitude: Double?,
        longitude: Double?,
        distance: Double,
        results: Int
    ) async {
        do {
            let fetched = try await service.fetchStations(
                latitude: latitude,
                longitude: longitude,
                distanceKm: distance,
                maxResults: results
            )
            chargingStations = fetched
            errorMessage = nil
            showRetryWithoutLocation = false
        } catch {
            errorMessage = error.localizedDescription
            showRetryWithoutLocation = false
        }
    }

    // MARK: - Selection / cancellation
    public func selectStation(_ station: ChargingStation?) {
        selectedStation = station
    }

    public func cancelLoading() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        Task { @MainActor in self.isLoading = false }
    }

    // MARK: - Helpers
    public func station(withID id: Int) -> ChargingStation? {
        chargingStations.first { $0.id == id }
    }
}
