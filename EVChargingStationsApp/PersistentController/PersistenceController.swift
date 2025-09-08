//
//  PersistenceController.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import CoreData

#if canImport(SwiftData)
import SwiftData
#endif

public protocol PersistenceProtocol {
    func saveStations(_ stations: [ChargingStation])
    func fetchStations() -> [ChargingStation]
}

public final class PersistenceController: PersistenceProtocol {
    public static let shared = PersistenceController()

    // MARK: - SwiftData (iOS 17+)
    #if canImport(SwiftData)
    @available(iOS 17.0, *)
    public var dataContainer: ModelContainer {
        do {
            return try ModelContainer(for: SDCachedChargingStation.self)
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }
    #endif

    // MARK: - CoreData (iOS 15/16)
    private lazy var coreDataContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EVChargingStations")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load CoreData store: \(error)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext { coreDataContainer.viewContext }

    // MARK: - Save
    public func saveStations(_ stations: [ChargingStation]) {
        #if canImport(SwiftData)
        if #available(iOS 17, *) {
            let context = ModelContext(dataContainer)
            for station in stations {
                let cached = SDCachedChargingStation.fromDomain(station)
                context.insert(cached)
            }
            do {
                try context.save()
            } catch {
                print("SwiftData save failed: \(error)")
            }
            return
        }
        #endif

        // CoreData path (iOS 15/16)
        for station in stations {
            _ = CDCachedChargingStation.fromDomain(station, context: context)
        }
        do {
            try context.save()
        } catch {
            print("CoreData save failed: \(error)")
        }
    }

    // MARK: - Fetch
    public func fetchStations() -> [ChargingStation] {
        #if canImport(SwiftData)
        if #available(iOS 17, *) {
            let context = ModelContext(dataContainer)
            let descriptor = FetchDescriptor<SDCachedChargingStation>()
            let cached = (try? context.fetch(descriptor)) ?? []
            return cached.map { $0.toDomain() }
        }
        #endif

        // CoreData path (iOS 15/16)
        let request: NSFetchRequest<CDCachedChargingStation> = CDCachedChargingStation.fetchRequest()
        let cached = (try? context.fetch(request)) ?? []
        return cached.map { $0.toDomain() }
    }
}
