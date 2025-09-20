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

enum CacheError: Error {
    case invalidFile
}

class FFResourceCacheManager {
    static let shared = FFResourceCacheManager()

    // Temporary constant variable for now
    let photoCacheMaximumSize: UInt64 = 200 * 1024 * 1024  // 200 MB
    var currentSizeOfCache: UInt64

    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "AssetManager")
    let persistedPhotoCacheFolder = FileManager.photoCacheDirectory

    private let objectContext = FFCoreDataManager.shared.newChildContext()

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
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }

    /// This will move the file from the given URL into the cache and create a corresponding CachedResource object
    func insert(remoteResource: RemoteResource, fileUrl: URL) throws {
        guard let fileSize = FileManager.default.sizeOfFile(at: fileUrl) else {
            throw CacheError.invalidFile
        }

        let cachedResource = CachedResource(context: objectContext)
        cachedResource.remoteResource = objectContext.object(with: remoteResource.objectID) as? RemoteResource
        cachedResource.fileName = UUID()
        cachedResource.fileSize = fileSize
        cachedResource.lastAccessDate = Date()

        let destinationUrl = persistedPhotoCacheFolder.appendingPathComponent(cachedResource.fileName!.uuidString)

        do {
            try FileManager.default.moveItem(at: fileUrl, to: destinationUrl)
            currentSizeOfCache += UInt64(fileSize)

            ensureCacheSizeLimit()
        } catch {
            objectContext.delete(cachedResource)

            throw error
        }
        
        try objectContext.save()
    }
}

extension CachedResource {
    override public func prepareForDeletion() {
        super.prepareForDeletion()

        FFResourceCacheManager.shared.delete(self)
    }
}
