//
//  ChargingStationsListView.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import SwiftUI
import MapKit

// MARK: - ChargingStationsListView

/// Displays a list of nearby charging stations.
/// - Uses a `ChargingStationsViewModel` for state and data.
/// - Handles loading, error, success, and "retry without location" flows.
/// - Navigates to `ChargingStationDetailView` on row selection.
public struct ChargingStationsListView: View {
    @StateObject private var viewModel: ChargingStationsViewModel

    public init(viewModel: ChargingStationsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.chargingStations.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Finding nearby stations…")
                    Spacer()
                }
            } else if let error = viewModel.errorMessage, viewModel.chargingStations.isEmpty {
                VStack(spacing: 12) {
                    Text("Uh oh")
                        .font(.title2)
                        .bold()
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("Retry") {
                        viewModel.fetchChargingStations(useLocation: true)
                    }
                    .padding(.top)

                    if viewModel.showRetryWithoutLocation {
                        Button("Retry without location") {
                            viewModel.retryWithoutLocation()
                        }
                        .padding(.top, 6)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.chargingStations) { station in
                        NavigationLink(
                            destination: ChargingStationDetailView(chargingStation: station)
                        ) {
                            ChargingStationRowView(chargingStation: station)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetchChargingStations(useLocation: true)
                }
            }
        }
        .navigationTitle("Nearby Stations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.fetchChargingStations(useLocation: true)
        }
    }
}

// MARK: - ChargingStationRowView

/// Compact row representation of a single charging station.
private struct ChargingStationRowView: View {
    let chargingStation: ChargingStation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(chargingStation.title)
                .font(.headline)
                .lineLimit(1)

            if !chargingStation.subtitle.isEmpty {
                Text(chargingStation.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
