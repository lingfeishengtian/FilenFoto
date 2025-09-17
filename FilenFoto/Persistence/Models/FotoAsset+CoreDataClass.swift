//
//  FotoAsset+CoreDataClass.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/15/25.
//
//

import CoreData
import Foundation
import Photos

public class FotoAsset: NSManagedObject {
    @CoreDataEnumAttribute(keyPath: \.mediaSubtypesRaw) var mediaSubtypes: PHAssetMediaSubtype
    @CoreDataEnumAttribute(keyPath: \.mediaTypeRaw) var mediaType: PHAssetMediaType
    
    var countOfRemoteResources: Int {
        remoteResources?.count ?? 0
    }
}
