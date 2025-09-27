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
    
    func resizedImageWith(image: UIImage, targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let newWidth  = targetSize.width  / image.size.width
        let newHeight = targetSize.height / image.size.height
        var newSize: CGSize

        if(newWidth > newHeight) {
            newSize = CGSizeMake(imageSize.width * newHeight, imageSize.height * newHeight)
        } else {
            newSize = CGSizeMake(imageSize.width * newWidth,  imageSize.height * newWidth)
        }

        let rect = CGRectMake(0, 0, newSize.width, newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)

        image.draw(in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
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
