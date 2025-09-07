//
//  ChargingStationModel.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import CoreLocation

// MARK: - ChargingStation

public struct ChargingStation: Decodable, Identifiable, Hashable {
    public let id: Int
    public let uuid: String?
    public let addressInfo: AddressInfo
    public let connections: [Connection]?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case uuid = "UUID"
        case addressInfo = "AddressInfo"
        case connections = "Connections"
    }

    public var title: String { addressInfo.title ?? "Unknown location" }

    public var subtitle: String {
        var parts: [String] = []
        if let town = addressInfo.town, !town.isEmpty { parts.append(town) }
        if let state = addressInfo.stateOrProvince, !state.isEmpty { parts.append(state) }
        if let postcode = addressInfo.postcode, !postcode.isEmpty { parts.append(postcode) }
        if parts.isEmpty, let line = addressInfo.addressLine1, !line.isEmpty {
            parts.append(line)
        }
        return parts.joined(separator: ", ")
    }
    
    public var detailedAddress: String {
        var parts: [String] = []
        if let line1 = addressInfo.addressLine1, !line1.isEmpty { parts.append(line1) }
        if let line2 = addressInfo.addressLine2, !line2.isEmpty { parts.append(line2) }
        if let town = addressInfo.town, !town.isEmpty { parts.append(town) }
        if let state = addressInfo.stateOrProvince, !state.isEmpty { parts.append(state) }
        if let postcode = addressInfo.postcode, !postcode.isEmpty { parts.append(postcode) }
        if let country = addressInfo.country?.title, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = addressInfo.latitude, let lon = addressInfo.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    public var connectorSummary: String {
        guard let connections = connections, !connections.isEmpty else { return "No connector data" }
        let parts = connections.prefix(2).map { conn -> String in
            var p: [String] = []
            if let t = conn.connectionType?.title { p.append(t) }
            if let kw = conn.powerKW { p.append("\(kw.cleanString) kW") }
            if let q = conn.quantity { p.append("\(q)x") }
            return p.joined(separator: " • ")
        }
        return parts.joined(separator: " — ")
    }
}

// MARK: - AddressInfo

public struct AddressInfo: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    public let addressLine1: String?
    public let addressLine2: String?
    public let town: String?
    public let stateOrProvince: String?
    public let postcode: String?
    public let latitude: Double?
    public let longitude: Double?
    public let accessComments: String?
    public let country: Country?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
        case addressLine1 = "AddressLine1"
        case addressLine2 = "AddressLine2"
        case town = "Town"
        case stateOrProvince = "StateOrProvince"
        case postcode = "Postcode"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case accessComments = "AccessComments"
        case country = "Country"
    }
}

// MARK: - Country

public struct Country: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    public let isoCode: String?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
        case isoCode = "ISOCode"
    }
}

// MARK: - Connection

public struct Connection: Decodable, Hashable {
    public let id: Int?
    public let powerKW: Double?
    public let quantity: Int?
    public let comments: String?
    public let connectionType: ConnectionType?
    public let currentType: CurrentType?
    public let statusType: StatusType?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case powerKW = "PowerKW"
        case quantity = "Quantity"
        case comments = "Comments"
        case connectionType = "ConnectionType"
        case currentType = "CurrentType"
        case statusType = "StatusType"
    }
}

public struct ConnectionType: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    private enum CodingKeys: String, CodingKey { case id = "ID"; case title = "Title" }
}

public struct CurrentType: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    private enum CodingKeys: String, CodingKey { case id = "ID"; case title = "Title" }
}

public struct StatusType: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    private enum CodingKeys: String, CodingKey { case id = "ID"; case title = "Title" }
}

// MARK: - OperatorInfo

public struct OperatorInfo: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    public let websiteURL: String?
    public let phonePrimaryContact: String?
    public let contactEmail: String?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
        case websiteURL = "WebsiteURL"
        case phonePrimaryContact = "PhonePrimaryContact"
        case contactEmail = "ContactEmail"
    }
}

// MARK: - UsageType

public struct UsageType: Decodable, Hashable {
    public let id: Int?
    public let title: String?
    private enum CodingKeys: String, CodingKey { case id = "ID"; case title = "Title" }
}

