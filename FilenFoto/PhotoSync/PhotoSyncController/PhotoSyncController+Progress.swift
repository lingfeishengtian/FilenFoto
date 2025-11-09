//
//  PhotoSyncController+Progress.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/28/25.
//

import Foundation

let WORKING_SET_ASSET_RETRIEVAL_UNITS: Int64 = 100

extension PhotoSyncController {
    private var singularPhotoProgressUnits: Int64 {
        AvailableProvider.totalProgressWeight + WORKING_SET_ASSET_RETRIEVAL_UNITS
    }
    
    func calculateTotalProgressUnits(for numberOfPhotos: Int) -> Int64 {
        Int64(numberOfPhotos) * singularPhotoProgressUnits
    }
    
    func completeWorkingSetAssetRetrieval() {
        progress.completedUnitCount += WORKING_SET_ASSET_RETRIEVAL_UNITS
    }
}
