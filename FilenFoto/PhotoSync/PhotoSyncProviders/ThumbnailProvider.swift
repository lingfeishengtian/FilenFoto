//
//  ThumbnailProvider.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import CoreData
import Foundation
import Photos
import UIKit

actor ThumbnailProvider: PhotoActionProviderDelegate {
    let version: Int16 = 1

    private init() {}
    static let shared = ThumbnailProvider()
    
    static let audioThumbnail = UIImage() // TODO: Load the default audio image from assets (maybe later generate thumbnail from soundwave???)
    
    func initiateProtocol(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion? {
        switch fotoAsset.mediaType {
        case .unknown:
            fatalError("Not supported for now")
        case .image:
            let resource = try await workingSetAsset.resource(for: .photo)
            let image = UIImage(contentsOfFile: resource.path())
            
            guard let image else {
                throw FilenFotoError.invalidImage
            }
            
            let compressedImage = compressImageToJpeg(image)
            
            guard let compressedImage else {
                // TODO: There might be some wonkiness in converting to jpeg. investigate this
                throw FilenFotoError.invalidImage
            }
            
            try storeThumbnail(compressedImage, for: fotoAsset)
        case .video:
            fatalError("Not supported for now")
        case .audio:
            fatalError("Not supported for now")
        @unknown default:
            fatalError("TODO: Fix this")
        }
        
        return nil
    }
    
    func incrementlyMigrate(_ workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, from currentVersion: Int16) async throws -> ProviderCompletion? {
        fatalError("No migrations required")
    }
    
    func retryFailedActions(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion? {
        try await initiateProtocol(for: workingSetAsset, with: fotoAsset)
    }
}
