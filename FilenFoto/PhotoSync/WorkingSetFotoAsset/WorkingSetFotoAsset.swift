//
//  WorkingSetObject.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/14/25.
//

import Foundation
import Photos.PHAssetResource
import os.log

enum WorkingSetError: Error {
    case missingResources
    case retrieveResourcesNotCalled
}

enum WorkingAssetState {
    case unknown
    case needsSync
    case needsDownloadFromCloud
    case alreadySynced
}

class WorkingSetFotoAsset {
    let asset: FotoAsset
    let assetManager: FFAssetManager = .init()
    let logger: Logger
    
    private var resourceState: WorkingAssetState = .unknown
    
    var workingSetRootFolder: URL {
        FileManager.workingSetDirectory.appendingPathComponent(asset.uuid!.uuidString, conformingTo: .folder)
    }

    init(asset: FotoAsset) {
        self.asset = asset
        self.logger = .init(subsystem: "com.github.hunterhan.FilenFoto", category: "WorkingSetFotoAsset")

        if asset.uuid == nil {
            fatalError("Asset must have a UUID")
        }
    }
    
    func retrieveResources(withSupportingPHAsset iosAsset: PHAsset? = nil) async throws {
        if iosAsset == nil && asset.countOfRemoteResources == 0 {
            throw WorkingSetError.missingResources
        }
        
        if let iosAsset {
            resourceState = try await assetManager.fetchAssets(for: asset, from: iosAsset, writeTo: workingSetRootFolder)
        } else {
            resourceState = .needsDownloadFromCloud
        }
        
        if asset.countOfRemoteResources == 0 {
            throw WorkingSetError.missingResources
        }
        
        if resourceState == .needsSync {
            try await assetManager.syncResources(in: workingSetRootFolder, for: asset)
            
            resourceState = .alreadySynced
        }
    }
    
    func resource(for resourceType: PHAssetResourceType) async throws -> URL? {
        if resourceState == .unknown {
            throw WorkingSetError.retrieveResourcesNotCalled
        }
        // TODO: Sync resources if needed
        
        // TODO: This should pull from cloud if its requested and the file isn't in cache.
        let remoteResource = asset.remoteResourcesArray.first {
            $0.assetResourceType == resourceType
        }
        
        let fileUrl = remoteResource?.fileURL(in: workingSetRootFolder)
        
        return fileUrl
    }
    
    deinit {
        for remoteResource in asset.remoteResourcesArray {
            let fileURL = remoteResource.fileURL(in: workingSetRootFolder)!
            
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
