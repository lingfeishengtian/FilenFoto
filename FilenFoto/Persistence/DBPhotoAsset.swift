//
//  DBPhotoAsste.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/9/24.
//

import Foundation
import SQLite
import Photos

struct DBPhotoAsset : Comparable, Hashable, Identifiable {
    static func < (lhs: DBPhotoAsset, rhs: DBPhotoAsset) -> Bool {
        if lhs.creationDate == rhs.creationDate {
            return lhs.localIdentifier < rhs.localIdentifier
        }
        return lhs.creationDate < rhs.creationDate
    }
    
    static func == (lhs: DBPhotoAsset, rhs: DBPhotoAsset) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
    
    var thumbnailURL: URL {
        PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailFileName)
    }
    
#if DEBUG
    func setId(_ idLocalID: String, idOffset: Int64) -> DBPhotoAsset {
        return DBPhotoAsset(id: id + 50000 + idOffset, localIdentifier: idLocalID, mediaType: mediaType, mediaSubtype: mediaSubtype, creationDate: Date.now - 9999999999999 - TimeInterval(Int(idLocalID) ?? 0), modificationDate: modificationDate, location: location, favorited: favorited, hidden: hidden, thumbnailFileName: thumbnailFileName, burstIdentifier: burstIdentifier, burstSelectionTypes: burstSelectionTypes)
    }
#endif
    
    var isBurst: Bool {
        burstIdentifier != nil
    }
    
    let id: Int64
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let mediaSubtype: PHAssetMediaSubtype
    let creationDate: Date
    let modificationDate: Date
    let location: CLLocation?
    let favorited: Bool
    let hidden: Bool
    let thumbnailFileName: String
    let burstIdentifier: String?
    let burstSelectionTypes: PHAssetBurstSelectionType
}
