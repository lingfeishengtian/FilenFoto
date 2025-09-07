//
//  FFCoreDataManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import Foundation
import CoreData

class FFCoreDataManager {
    static let shared = FFCoreDataManager()
    let managedObjectContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "FilenFotoModel")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        managedObjectContext = persistentContainer.viewContext
    }
}
