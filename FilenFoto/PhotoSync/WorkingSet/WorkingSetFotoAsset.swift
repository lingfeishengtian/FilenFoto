//
//  WorkingSetObject.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/14/25.
//

import Foundation
import CoreData
import Photos.PHAssetResource
import os.log
import UIKit

enum WorkingAssetState {
    case unknown
    case needsSync
    case needsDownloadFromCloud
    case alreadySynced
}

actor WorkingSetFotoAsset {
    let asset: FotoAsset
    let workingSetRootFolder: URL
    let assetManager: FFResourceManager = .init()
    let logger: Logger

    private var resourceState: WorkingAssetState = .unknown
    
    var thumbnail: UIImage? {
        ThumbnailProvider.shared.thumbnail(for: asset)
    }
    
    init(asset: FotoAsset) {
        if asset.uuid == nil {
            fatalError("Asset must have a UUID")
        }
        
        self.asset = asset
        self.workingSetRootFolder = FileManager.workingSetDirectory.appendingPathComponent(asset.uuid!.uuidString, conformingTo: .folder)
        self.logger = .init(subsystem: "com.github.hunterhan.FilenFoto", category: "WorkingSetFotoAsset")
    }
    
    func retrieveResources(withSupportingPHAsset iosAsset: PHAsset? = nil) async throws {
        if iosAsset == nil && asset.countOfRemoteResources == 0 {
            throw FilenFotoError.missingResources
        }
        
        let isAssetInBackgroundContext = await FFCoreDataManager.shared.validateIsInBackgroundContext(object: asset)
        if !isAssetInBackgroundContext {
            throw FilenFotoError.coreDataContext
        }
        
        if let iosAsset {
            resourceState = try await assetManager.fetchAssets(for: asset, from: iosAsset, writeTo: workingSetRootFolder)
        } else {
            resourceState = .needsDownloadFromCloud
        }
        
        if asset.countOfRemoteResources == 0 {
            throw FilenFotoError.missingResources
        }
        
        if resourceState == .needsSync {
            try await assetManager.syncResources(in: workingSetRootFolder, for: asset)
            
            resourceState = .alreadySynced
        }
    }
    
    func resource(for resourceType: PHAssetResourceType, cancellable: Bool = false) async throws -> URL {
        try? FileManager.default.createDirectory(at: workingSetRootFolder, withIntermediateDirectories: true)

        let objectContext = FFCoreDataManager.shared.newChildContext()
        let remoteResourceObjectId = asset.remoteResourcesArray.first {
            $0.assetResourceType == resourceType
        }?.objectID
        
        guard let remoteResourceObjectId, let remoteResource = objectContext.object(with: remoteResourceObjectId) as? RemoteResource else {
            throw FilenFotoError.remoteResourceNotFoundInFilen
        }
        
        let fileUrl = remoteResource.fileURL(in: workingSetRootFolder)
        
        guard let fileUrl else {
            throw FilenFotoError.invalidFile
        }
        
        if FileManager.default.fileExists(atPath: fileUrl.path()) {
            await cache(remoteResource)
            return fileUrl
        }
        
        if let cachedResource = remoteResource.cachedResource,
            await FFResourceCacheManager.shared.copyCache(from: cachedResource, to: fileUrl) {
            return fileUrl
        }
        
        try await assetManager.filenDownload(resource: remoteResource, toLocalFolder: workingSetRootFolder, cancellable: cancellable)
        await cache(remoteResource)

        return fileUrl
    }
    
    func asset(in temporaryContext: NSManagedObjectContext) -> FotoAsset? {
        temporaryContext.object(with: self.asset.objectID) as? FotoAsset
    }
    
    func cache(_ remoteResource: RemoteResource) async {
        let fileURL = remoteResource.fileURL(in: workingSetRootFolder)!
        let doesFileExist = FileManager.default.fileExists(atPath: fileURL.path())
        
        if !doesFileExist {
            return
        }
        
        do {
            try await FFResourceCacheManager.shared.insert(remoteResource: remoteResource, fileUrl: fileURL)
        } catch {
            logger.error("Failed to insert remote resource into cache or failed to cancel download: \(error)")
        }
    }
    
    deinit {
        // Clean working directory just in case a session before exited abnormally
        for remoteResource in asset.remoteResourcesArray {
            try? assetManager.cancelDownload(resource: remoteResource)
        }
        
        try? FileManager.default.clearDirectoryContents(at: workingSetRootFolder)
        try? FileManager.default.removeItem(at: workingSetRootFolder)
    }
}
