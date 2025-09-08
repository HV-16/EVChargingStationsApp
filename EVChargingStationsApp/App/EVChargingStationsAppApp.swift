//
//  EVChargingStationsApp.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/6/25.
//

import SwiftUI

@main
struct EVChargingStationsApp: App {
    private let networkClient: NetworkClient
    private let openChargeService: OpenChargeMapService
    private let stationsViewModel: ChargingStationsViewModel
    private let locationManager = LocationManager()
    private let persistence: PersistenceController

    init() {
        // Network + Service
        self.networkClient = NetworkClient(session: .shared, requestTimeout: 30)
        self.openChargeService = OpenChargeMapService(client: networkClient)
        self.persistence = .shared

        // ViewModel
        self.stationsViewModel = ChargingStationsViewModel(
            service: openChargeService,
            locationProvider: locationManager,
            persistence: persistence
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if #available(iOS 17, *) {
                    NavigationStack {
                        ChargingStationsListView(viewModel: stationsViewModel)
                    }
                } else if #available(iOS 16, *) {
                    NavigationStack {
                        ChargingStationsListView(viewModel: stationsViewModel)
                    }
                } else {
                    NavigationView {
                        ChargingStationsListView(viewModel: stationsViewModel)
                    }
                }
            }
        }
    }
}
