//
//  FFCoreDataManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import Foundation
import CoreData
import os

class FFCoreDataManager {
    static let shared = FFCoreDataManager()
    let mainThreadManagedContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "CoreData")
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "FilenFotoModel")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        mainThreadManagedContext = persistentContainer.viewContext
        backgroundContext = persistentContainer.newBackgroundContext()
    }
}
