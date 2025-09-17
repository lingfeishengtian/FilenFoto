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
}

class WorkingSetFotoAsset {
    let asset: FotoAsset
    let assetManager: FFAssetManager = .init()
    
    var workingSetRootFolder: URL {
        FileManager.workingSetDirectory.appendingPathComponent(asset.uuid!.uuidString, conformingTo: .folder)
    }

    init(asset: FotoAsset) {
        self.asset = asset

        if asset.uuid == nil {
            fatalError("Asset must have a UUID")
        }
    }
    
    func backupAssetsToFilen(withSupportingPHAsset iosAsset: PHAsset? = nil) async throws {
        if iosAsset == nil && asset.countOfRemoteResources == 0 {
            throw WorkingSetError.missingResources
        }
        
        if let iosAsset {
            try await assetManager.fetchAssets(for: asset, from: iosAsset, writeTo: workingSetRootFolder)
        }
        
        if asset.countOfRemoteResources == 0 {
            throw WorkingSetError.missingResources
        }
        
        try await assetManager.uploadAssets(in: workingSetRootFolder, for: asset)
    }
}
