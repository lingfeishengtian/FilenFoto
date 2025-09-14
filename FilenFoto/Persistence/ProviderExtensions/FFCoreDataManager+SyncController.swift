//
//  FFCoreDataManager+SyncController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/7/25.
//

import Foundation
import CoreData
import Photos.PHAsset

extension FFCoreDataManager {
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
    
    func insert(for phAsset: PHAsset) -> FotoAsset {
        if let existingFotoAsset = findFotoAsset(for: phAsset.localIdentifier) {
            return existingFotoAsset
        }
        
        let newFotoAsset = FotoAsset(context: backgroundContext)
        set(filenFoto: newFotoAsset, for: phAsset)
        
        backgroundContext.insert(newFotoAsset)
        if backgroundContext.insertedObjects.count > 100 {
            saveContextIfNeeded()
        }
        
        return newFotoAsset
    }
    
    func saveContextIfNeeded() {
        if backgroundContext.hasChanges {
            do {
                logger.info("Saving background context with \(self.backgroundContext.insertedObjects.count) inserted objects, \(self.backgroundContext.updatedObjects.count) updated objects, and \(self.backgroundContext.deletedObjects.count) deleted objects.")
                try backgroundContext.save()
            } catch {
                logger.error("Error saving background context: \(error)")
                // TODO: Handle error
            }
        }
    }
}

extension FFCoreDataManager {
    func set(filenFoto: FotoAsset, for asset: PHAsset) {
//        filenFoto.cloudUuid = asset. TODO: Figure out
        filenFoto.localUuid = asset.localIdentifier
        filenFoto.dateCreated = asset.creationDate
        filenFoto.dateModified = asset.modificationDate
        filenFoto.mediaType = Int16(asset.mediaType.rawValue)
        filenFoto.mediaSubtypes = Int64(asset.mediaSubtypes.rawValue)
        filenFoto.pixelHeight = Int64(asset.pixelHeight)
        filenFoto.pixelWidth = Int64(asset.pixelWidth)
    }
}
