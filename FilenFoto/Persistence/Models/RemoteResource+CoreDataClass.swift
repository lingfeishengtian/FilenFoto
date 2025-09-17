//
//  RemoteResource+CoreDataClass.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/15/25.
//
//

import CoreData
import Foundation
import Photos.PHAssetResource
import CryptoKit

public class RemoteResource: NSManagedObject {
    @CoreDataEnumAttribute(keyPath: \.assetResourceTypeRaw) var assetResourceType: PHAssetResourceType
}
