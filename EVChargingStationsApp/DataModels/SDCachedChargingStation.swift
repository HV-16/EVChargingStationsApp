//
//  SDCachedChargingStation.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@Model
public final class SDCachedChargingStation {
    @Attribute(.unique) public var id: Int64
    public var title: String
    public var subtitle: String
    public var detailedAddress: String
    public var latitude: Double?
    public var longitude: Double?
    public var connectorSummary: String = ""
    public var lastUpdated: Date

    public init(
        id: Int64,
        title: String = "",
        subtitle: String = "",
        detailedAddress: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        connectorSummary: String = "",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.detailedAddress = detailedAddress
        self.latitude = latitude
        self.longitude = longitude
        self.connectorSummary = connectorSummary
        self.lastUpdated = lastUpdated
    }
}
#endif
