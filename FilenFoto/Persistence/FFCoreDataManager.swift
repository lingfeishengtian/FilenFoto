//
//  FFCoreDataManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import Foundation
import CoreData
import Photos
import os

actor FFCoreDataManager {
    static let shared = FFCoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "CoreData")
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "FilenFotoModel")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    // TODO: Make this phone specific and probably move this out of the actor, this operation takes too long
    func findFotoAsset(for localUuid: String) -> FotoAsset? {
        let fetchRequest = FotoAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "localUuid == %@", localUuid)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try backgroundContext.fetch(fetchRequest)
            return results.first
        } catch {
            logger.error("Error checking for existing UUID: \(error)")
            return nil
        }
    }
    
    nonisolated func validateIsInBackgroundContext(object: NSManagedObject) -> Bool {
        object.managedObjectContext === backgroundContext
    }
    
    func insert(for phAsset: PHAsset) -> FotoAsset {
        if let existingFotoAsset = findFotoAsset(for: phAsset.localIdentifier) {
            return existingFotoAsset
        }
        
        let newFotoAsset = FotoAsset(context: backgroundContext)
        set(filenFoto: newFotoAsset, for: phAsset)
        
        backgroundContext.insert(newFotoAsset)
        saveContextIfNeeded()
        
        return newFotoAsset
    }
    
    @MainActor
    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    nonisolated var managedObjectModel: NSManagedObjectModel {
        persistentContainer.managedObjectModel
    }
    
    func saveContextIfNeeded() {
        backgroundContext.performAndWait { [self] in
            if backgroundContext.hasChanges {
                do {
                    logger.info("Saving background context with \(self.backgroundContext.insertedObjects.count) inserted objects, \(self.backgroundContext.updatedObjects.count) updated objects, and \(self.backgroundContext.deletedObjects.count) deleted objects.")
                    try backgroundContext.save()
                } catch {
                    // TODO: Handle error
                    assert(true)
                    logger.error("Error saving background context: \(error)")
                }
            }
        }
    }
    
    nonisolated func newChildContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = backgroundContext
        
        return childContext
    }
    
    nonisolated func readOnly<T: NSManagedObject>(from objectId: FFObjectID<T>) -> ReadOnlyNSManagedObject<T>? {
        let object = backgroundContext.object(with: objectId.raw) as? T
        
        guard let object else {
            return nil
        }
        
        return .init(object)
    }
}
