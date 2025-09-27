//
//  ThumbnailProvider.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import CoreData
import Foundation
import UIKit

actor ThumbnailProvider: PhotoActionProviderDelegate {
    let version: Int16 = 2

    private init() {}
    static let shared = ThumbnailProvider()

    static let audioThumbnail = UIImage()  // TODO: Load the default audio image from assets (maybe later generate thumbnail from soundwave???)

    func initiateProtocol(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion? {
        let image = try await imageResource(for: workingSetAsset, mediaType: fotoAsset.mediaType)
        try image.exportToRawThumbnail(
            at: destinationUrl(for: fotoAsset),
            targetSize: compressedPixelSize(
                pixelHeight: fotoAsset.pixelHeight,
                pixelWidth: fotoAsset.pixelWidth
            )
        )

        return nil
    }
    
    func incrementlyMigrate(_ workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, from currentVersion: Int16) async throws
        -> ProviderCompletion?
    {
        switch currentVersion {
        case 1:
            return try await initiateProtocol(for: workingSetAsset, with: fotoAsset)
        default:
            return nil
        }
    }

    func retryFailedActions(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion? {
        try await initiateProtocol(for: workingSetAsset, with: fotoAsset)
    }
}
