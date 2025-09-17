//
//  FFAssetManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import CoreData
import Foundation
import os.log
import Photos.PHAssetResource


enum CacheError: Error {
    case invalidFile
}

class FFResourceCacheManager {
    static let shared = FFResourceCacheManager()
    private init() {}

    // Temporary constant variable for now
    let photoCacheMaximumSize: UInt64 = 200 * 1024 * 1024  // 200 MB
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "AssetManager")
    let persistedPhotoCacheFolder = FileManager.photoCacheDirectory

    // TODO: Register onto FotoAsset for an onDelete trigger to remove from cache

    var currentSizeOfCache: UInt64 = {
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
            let fetchedQueryResult = try FFCoreDataManager.shared.backgroundContext.fetch(cacheFetchRequest)

            guard let resultDict = fetchedQueryResult.first as? [String: Any],
                let totalFileSize = resultDict["totalFileSize"] as? UInt64
            else {
                return 0
            }

            return totalFileSize
        } catch {
            FFResourceCacheManager.shared.logger.error("Failed to fetch cache size: \(error.localizedDescription)")
            return 0
        }
    }()

    func delete(_ cachedResource: CachedResource) {
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

        let fetchRequest = NSFetchRequest<CachedResource>(entityName: "CachedResource")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(CachedResource.lastAccessDate), ascending: true)]
        
        // Delete until we're under the limit
        let context = FFCoreDataManager.shared.backgroundContext
        let fetchedAssets: [CachedResource] = (try? context.fetch(fetchRequest)) ?? []
        for cachedAsset in fetchedAssets {
            if currentSizeOfCache <= photoCacheMaximumSize {
                break
            }
            
            context.delete(cachedAsset)
        }
    }
    
    /// This will move the file from the given URL into the cache and create a corresponding CachedResource object
    func insert(remoteResource: RemoteResource, fileUrl: URL) throws {
        guard let fileSize = FileManager.default.sizeOfFile(at: fileUrl) else {
            throw CacheError.invalidFile
        }
        
        let context = FFCoreDataManager.shared.backgroundContext
        let cachedResource = CachedResource(context: context)
        cachedResource.remoteResource = remoteResource
        cachedResource.fileName = UUID()
        cachedResource.fileSize = fileSize
        cachedResource.lastAccessDate = Date()
        
        let destinationUrl = persistedPhotoCacheFolder.appendingPathComponent(cachedResource.fileName!.uuidString)
        
        do {
            try FileManager.default.moveItem(at: fileUrl, to: destinationUrl)
            currentSizeOfCache += UInt64(fileSize)
            
            ensureCacheSizeLimit()
        } catch {
            context.delete(cachedResource)
            
            throw error
        }
    }
}

extension CachedResource {
    override public func prepareForDeletion() {
        super.prepareForDeletion()

        FFResourceCacheManager.shared.delete(self)
    }
}
