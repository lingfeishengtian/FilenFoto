//
//  FFAssetManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import CoreData
import Foundation
import Photos.PHAssetResource
import os.log

actor FFResourceCacheManager {
    static let shared = FFResourceCacheManager()

    // Temporary constant variable for now
    let photoCacheMaximumSize: UInt64 = 200 * 1024 * 1024  // 200 MB
    var currentSizeOfCache: UInt64

    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "AssetManager")
    let persistedPhotoCacheFolder = FileManager.photoCacheDirectory

    // TODO: Register onto FotoAsset for an onDelete trigger to remove from cache


    private init() {
        self.currentSizeOfCache = 0

        let cacheFetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedResource.fetchRequest()

        let sumExpression = NSExpression(
            forFunction: "sum:",
            arguments: [
                NSExpression(forKeyPath: #keyPath(CachedResource.fileSize))
            ])

        let sumExpressionDescription = NSExpressionDescription()
        sumExpressionDescription.name = "totalFileSize"
        sumExpressionDescription.expression = sumExpression
        sumExpressionDescription.expressionResultType = .integer64AttributeType

        cacheFetchRequest.resultType = .dictionaryResultType
        cacheFetchRequest.propertiesToFetch = [sumExpressionDescription]

        do {
            let objectContext = FFCoreDataManager.shared.newChildContext()
            let fetchedQueryResult = try objectContext.fetch(cacheFetchRequest)

            if let resultDict = fetchedQueryResult.first as? [String: Any],
                let totalFileSize = resultDict["totalFileSize"] as? UInt64
            {
                self.currentSizeOfCache = totalFileSize
            }
        } catch {
            logger.error("Failed to fetch cache size: \(error.localizedDescription)")
        }
    }

    /// I allow this to be CachedResource since the only caller will be CachedResource itself
    fileprivate func delete(_ cachedResource: CachedResource) async {
        guard let name = cachedResource.fileName else {
            logger.error("Tried to delete cached asset file but the CachedAsset had no fileName")

            return
        }

        let fileURL = persistedPhotoCacheFolder.appendingPathComponent(name.uuidString)

        do {
            try FileManager.default.removeItem(at: fileURL)
            currentSizeOfCache -= UInt64(cachedResource.fileSize)
        } catch {
            logger.error("Failed to delete cached asset file at \(fileURL.path): \(error.localizedDescription)")
        }
    }

    func ensureCacheSizeLimit() {
        if currentSizeOfCache <= photoCacheMaximumSize {
            return
        }

        let objectContext = FFCoreDataManager.shared.newChildContext()
        
        let fetchRequest = CachedResource.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(CachedResource.lastAccessDate), ascending: true)]

        // Delete until we're under the limit
        let fetchedAssets: [CachedResource] = (try? objectContext.fetch(fetchRequest)) ?? []
        for cachedAsset in fetchedAssets {
            if currentSizeOfCache <= photoCacheMaximumSize {
                break
            }

            objectContext.delete(cachedAsset)
        }
        
        do {
            try objectContext.save()
            
            Task {
                await FFCoreDataManager.shared.saveContextIfNeeded()
            }
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }

    /// This will move the file from the given URL into the cache and create a corresponding CachedResource object
    func insert(remoteResourceId: FFObjectID<RemoteResource>, fileUrl: URL) async throws {
        guard let fileSize = FileManager.default.sizeOfFile(at: fileUrl) else {
            throw FilenFotoError.invalidFile
        }
        
        try await withTemporaryManagedObjectContext(remoteResourceId) { remoteResource, objectContext in
            if let cachedResource = remoteResource.cachedResource {
                cachedResource.lastAccessDate = .now
                return
            }
            
            let cachedResource = CachedResource(context: objectContext)
            cachedResource.remoteResource = remoteResource
            cachedResource.fileName = UUID()
            cachedResource.fileSize = fileSize
            cachedResource.lastAccessDate = Date()
            
            let destinationUrl = persistedPhotoCacheFolder.appendingPathComponent(cachedResource.fileName!.uuidString)
            
            do {
                try FileManager.default.copyItem(at: fileUrl, to: destinationUrl)
                currentSizeOfCache += UInt64(fileSize)
                
                ensureCacheSizeLimit()
            } catch {
                objectContext.delete(cachedResource)
                
                throw error
            }
        }
    }
    
    // TODO: Temp move all instances of getting the cache directory into an extension of the cache NSManagedObject
    func copyCache(from cachedResourceId: FFObjectID<CachedResource>, to destinationURL: URL) async -> Bool {
        do {
            return try await withTemporaryManagedObjectContext(cachedResourceId) { cachedResource, objectContext in
                cachedResource.lastAccessDate = .now
                let cachedUrlLocation = persistedPhotoCacheFolder.appending(path: cachedResource.fileName!.uuidString)
                
                do {
                    try FileManager.default.copyItem(at: cachedUrlLocation, to: destinationURL)
                    return true
                } catch {
                    logger.warning("The cache file doesn't exist at \(cachedUrlLocation) or \(error), deleting the CacheResource")
                }
                
                objectContext.delete(cachedResource)
                return false
            }
        } catch {
            logger.error("Found context error: \(error)")
            
            return false
        }
    }
}

extension CachedResource {
    override public func prepareForDeletion() {
        super.prepareForDeletion()

        Task {
            await FFResourceCacheManager.shared.delete(self)
        }
    }
}
