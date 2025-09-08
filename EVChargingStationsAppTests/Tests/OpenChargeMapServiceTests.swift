//
//  OpenChargeMapServiceTests.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import Testing
@testable import EVChargingStationsApp

@Suite("OpenChargeMapService suite")
struct OpenChargeMapServiceTests {

    private func sampleStationJSON() -> Data {
        let json = """
        [
          {
            "ID": 12345,
            "UUID": "1111-2222",
            "AddressInfo": {
              "ID": 1,
              "Title": "Test Station",
              "AddressLine1": "1 Test St",
              "Town": "Testville",
              "StateOrProvince": "TS",
              "Postcode": "12345",
              "Latitude": 12.34,
              "Longitude": 56.78,
              "AccessComments": "24/7",
              "Country": {
                "ID": 44,
                "Title": "Testland",
                "ISOCode": "TL"
              }
            },
            "Connections": []
          }
        ]
        """
        return Data(json.utf8)
    }

    @Test("fetchStations with lat/lon builds URL and decodes payload")
    func testPoiURLBuiltAndDecoded() async throws {
        let client = MockNetworkClient()
        client.responseData = sampleStationJSON()

        let service = OpenChargeMapService(client: client)

        let stations = try await service.fetchStations(
            latitude: 12.34,
            longitude: 56.78,
            distanceKm: 5,
            maxResults: 10
        )
        #expect(stations.count == 1)
        #expect(stations.first?.id == 12345)
        #expect(stations.first?.title == "Test Station")

        let url = try #require(client.lastRequest?.url)
        let urlStr = url.absoluteString.lowercased()
        #expect(urlStr.contains("latitude=12.34"))
        #expect(urlStr.contains("longitude=56.78"))
        #expect(urlStr.contains("distance=5"))
        #expect(urlStr.contains("maxresults=10"))
    }

    @Test("fetchStations without location uses generic endpoint")
    func testFetchWithoutLocation() async throws {
        let client = MockNetworkClient()
        client.responseData = sampleStationJSON()

        let service = OpenChargeMapService(client: client)

        let stations = try await service.fetchStations(
            latitude: nil,
            longitude: nil,
            distanceKm: nil,
            maxResults: 5
        )
        #expect(stations.count == 1)
        #expect(stations.first?.title == "Test Station")

        let url = try #require(client.lastRequest?.url)
        let urlStr = url.absoluteString.lowercased()
        #expect(urlStr.contains("maxresults=5"))
        #expect(!urlStr.contains("latitude="))
        #expect(!urlStr.contains("longitude="))
    }
}
