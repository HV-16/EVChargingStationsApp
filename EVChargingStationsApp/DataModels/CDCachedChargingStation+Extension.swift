//
//  CDCachedChargingStation+Extension.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import CoreData

extension CDCachedChargingStation {
    func toDomain() -> ChargingStation {
        let addressInfo = AddressInfo(
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
            addressInfo: addressInfo,
            connections: nil
        )
    }
    
    static func fromDomain(
        _ chargingStation: ChargingStation,
        context: NSManagedObjectContext
    ) -> CDCachedChargingStation {
        let cached = CDCachedChargingStation(context: context)
        cached.id = Int64(chargingStation.id)
        cached.title = chargingStation.title
        cached.subtitle = chargingStation.subtitle
        cached.detailedAddress = chargingStation.detailedAddress
        cached.latitude = chargingStation.coordinate?.latitude ?? 0.0
        cached.longitude = chargingStation.coordinate?.longitude ?? 0.0
        cached.connectorSummary = chargingStation.connectorSummary
        cached.lastUpdated = Date()
        return cached
    }
}
