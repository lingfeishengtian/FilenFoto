//
//  FFMockDataGenerator.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/16/25.
//

import Foundation
import CoreData
import Photos

#if DEBUG
class FFMockDataGenerator {
    static func generateFotoAsset() -> FotoAsset {
        let backgroundContext = FFCoreDataManager.shared.newChildContext()
        let fotoAsset = FotoAsset(
            context: backgroundContext
        )
        
        fotoAsset.uuid = UUID()
        fotoAsset.localUuid = UUID().uuidString
        fotoAsset.dateCreated = .now
        fotoAsset.dateModified = .now
        fotoAsset.mediaType = .image
        fotoAsset.mediaSubtypes = [.photoHDR]
        fotoAsset.pixelHeight = 1000
        fotoAsset.pixelWidth = 1000
        
        try! backgroundContext.save()
        
        return fotoAsset
    }
    
    static func generateWorkingSetFotoAsset() -> WorkingSetFotoAsset {
        WorkingSetFotoAsset(asset: typedID(generateFotoAsset()))
    }
}
#endif
