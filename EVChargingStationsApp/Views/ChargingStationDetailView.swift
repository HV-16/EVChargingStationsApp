//
//  ChargingStationDetailView.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import SwiftUI
import MapKit

// MARK: - ChargingStationDetailView

/// Detailed view for a single charging station.
/// Displays a map snapshot, station title and address, access information,
/// and a list of connectors with their details.
public struct ChargingStationDetailView: View {
    public let chargingStation: ChargingStation
    
    public init(chargingStation: ChargingStation) {
        self.chargingStation = chargingStation
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let coord = chargingStation.coordinate {
                    Map(
                        coordinateRegion: .constant(
                            MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        ),
                        interactionModes: .all,
                        showsUserLocation: false,
                        annotationItems: [chargingStation]
                    ) { item in
                        MapMarker(coordinate: item.coordinate!, tint: .blue)
                    }
                    .frame(height: 220)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(chargingStation.title)
                        .font(.title2)
                        .bold()
                    
                    if !chargingStation.detailedAddress.isEmpty {
                        Text(chargingStation.detailedAddress)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let access = chargingStation.addressInfo.accessComments, !access.isEmpty {
                        Text("Access Comments")
                            .font(.headline)
                        Text(access)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connectors")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let connections = chargingStation.connections, !connections.isEmpty {
                        ForEach(connections.indices, id: \.self) { index in
                            let connection = connections[index]
                            ConnectorRowView(connection: connection)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                        }
                    } else {
                        Text("No connector details available.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding(.top)
        }
        .navigationTitle(chargingStation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ConnectorRowView

/// Row view for displaying information about a single connector.
/// Shows connector type, power, quantity, status, and optional comments.
private struct ConnectorRowView: View {
    let connection: Connection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(connection.connectionType?.title ?? "Unknown connector")
                .font(.subheadline)
                .bold()
            
            HStack(spacing: 10) {
                if let kw = connection.powerKW {
                    Text("\(kw.cleanString) kW")
                }
                if let qty = connection.quantity {
                    Text("\(qty)x")
                }
                if let status = connection.statusType?.title {
                    Text(status)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if let comments = connection.comments, !comments.isEmpty {
                Text(comments)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
