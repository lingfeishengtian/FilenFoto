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

enum WorkingAssetState {
    case unknown
    case needsSync
    case needsDownloadFromCloud
    case alreadySynced
}

actor WorkingSetFotoAsset {
    private let asset: FotoAsset
    let workingSetRootFolder: URL
    let assetManager: FFResourceManager = .init()
    let logger: Logger
    
    private var resourceState: WorkingAssetState = .unknown
    
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
    
    func resource(for resourceType: PHAssetResourceType) async throws -> URL {
        if resourceState == .unknown || resourceState == .needsSync {
            throw FilenFotoError.internalError("retrieveResources function was not called for asset: \(asset)")
        }
        
        let remoteResource = asset.remoteResourcesArray.first {
            $0.assetResourceType == resourceType
        }
        
        let fileUrl = remoteResource?.fileURL(in: workingSetRootFolder)
        
        guard let fileUrl else {
            throw FilenFotoError.invalidFile
        }
        
        if FileManager.default.fileExists(atPath: fileUrl.path()) {
            return fileUrl
        }
        
        guard let remoteResource else {
            throw FilenFotoError.remoteResourceNotFoundInFilen
        }
        
        if let cachedResource = remoteResource.cachedResource {
            try FFResourceCacheManager.shared.copyCache(from: cachedResource, to: fileUrl)
            
            return fileUrl
        }
        
        try await assetManager.filenDownload(resource: remoteResource, toLocalFolder: workingSetRootFolder)
        
        return fileUrl
    }
    
    func asset(in temporaryContext: NSManagedObjectContext) -> FotoAsset? {
        temporaryContext.object(with: self.asset.objectID) as? FotoAsset
    }
    
    deinit {
        for remoteResource in asset.remoteResourcesArray {
            let fileURL = remoteResource.fileURL(in: workingSetRootFolder)!
            let doesFileExist = FileManager.default.fileExists(atPath: fileURL.path())
            
            if !doesFileExist {
                continue
            }

            do {
                try FFResourceCacheManager.shared.insert(remoteResource: remoteResource, fileUrl: fileURL)
            } catch {
                logger.error("Failed to insert remote resource into cache: \(error)")

                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        // Clean working directory just in case a session before exited abnormally
        try? FileManager.default.clearDirectoryContents(at: workingSetRootFolder)
        try? FileManager.default.removeItem(at: workingSetRootFolder)
    }
}
