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
    func set(filenFoto: FotoAsset, for asset: PHAsset) {
//        filenFoto.cloudUuid = asset. TODO: Figure out
        filenFoto.uuid = UUID() // Although an extremely small chance, assume this is *mostly* unique and use it for operations that need a relatively stable identifier, however, don't set constraints on it
        filenFoto.localUuid = asset.localIdentifier
        filenFoto.dateCreated = asset.creationDate
        filenFoto.dateModified = asset.modificationDate
        filenFoto.mediaType = asset.mediaType
        filenFoto.mediaSubtypes = asset.mediaSubtypes
        filenFoto.pixelHeight = Int64(asset.pixelHeight)
        filenFoto.pixelWidth = Int64(asset.pixelWidth)
    }
}
