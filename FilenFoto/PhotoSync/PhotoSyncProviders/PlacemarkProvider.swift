//
//  PlacemarkProvider.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/16/25.
//

import Foundation
import MapKit
import Photos

actor PlacemarkProvider: PhotoActionProviderDelegate {
    let version: Int16 = 1
    
    private init() {}
    static let shared = PlacemarkProvider()
    
    func initiateProtocol(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, supportingPHAsset: PHAsset) async throws -> ProviderCompletion? {
        if let location = supportingPHAsset.location, let reverseGeocodingRequest = MKReverseGeocodingRequest(location: location) {
            let mapItems = try await reverseGeocodingRequest.mapItems
            if let mapItem = mapItems.first {
                try await withTemporaryManagedObjectContext(typedID(fotoAsset)) { fotoAsset, objectContext in
                    if let existingPlacemark = fotoAsset.placemark {
                        objectContext.delete(existingPlacemark)
                    }
                    
                    let placemark = FotoPlacemark(context: objectContext)
                    fotoAsset.placemark = placemark
                    FFCoreDataManager.set(placemark: placemark, for: mapItem)
                }
            }
        }
        
        return nil
    }
    
    func incrementlyMigrate(_ workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, supportingPHAsset: PHAsset, from currentVersion: Int16) async throws -> ProviderCompletion? {
        nil
    }
    
    func retryFailedActions(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, supportingPHAsset: PHAsset) async throws -> ProviderCompletion? {
        try await initiateProtocol(for: workingSetAsset, with: fotoAsset, supportingPHAsset: supportingPHAsset)
    }
}
