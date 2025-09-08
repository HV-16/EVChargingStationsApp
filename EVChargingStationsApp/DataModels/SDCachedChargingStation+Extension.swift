//
//  SDCachedChargingStation+Extension.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
extension SDCachedChargingStation {
    func toDomain() -> ChargingStation {
        let adressInfo = AddressInfo(
            id: nil,
            title: title,
            addressLine1: detailedAddress,
            addressLine2: nil,
            town: subtitle,
            stateOrProvince: nil,
            postcode: nil,
            latitude: latitude,
            longitude: longitude,
            accessComments: nil,
            country: nil
        )
        return ChargingStation(
            id: Int(id),
            uuid: nil,
            addressInfo: adressInfo,
            connections: nil
        )
    }

    static func fromDomain(
        _ chargingStation: ChargingStation
    ) -> SDCachedChargingStation {
        return SDCachedChargingStation(
            id: Int64(chargingStation.id),
            title: chargingStation.title,
            subtitle: chargingStation.subtitle,
            detailedAddress: chargingStation.detailedAddress,
            latitude: chargingStation.coordinate?.latitude,
            longitude: chargingStation.coordinate?.longitude,
            connectorSummary: chargingStation.connectorSummary,
            lastUpdated: Date()
        )
    }
}
#endif
