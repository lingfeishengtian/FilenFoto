//
//  ThumbnailProvider+FileUtilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/22/25.
//

import Foundation
import Photos
import UIKit

extension ThumbnailProvider {
    /// Assumes fotoAsset already has a UUID
    nonisolated func destinationUrl(for fotoAsset: ReadOnlyNSManagedObject<FotoAsset>) -> URL {
        let thumbnailIndex = fotoAsset.thumbnailIndex
        let directory = thumbnailIndex.directory(rootDirectory: FileManager.photoThumbnailDirectory)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory.appending(path: fotoAsset.uuid!.uuidString)
    }

//    func storeThumbnail(_ data: Data, for fotoAsset: FotoAsset) throws {
//        try data.write(to: destinationUrl(for: fotoAsset))
//    }
    
    nonisolated func thumbnail(for fotoAsset: ReadOnlyNSManagedObject<FotoAsset>) -> UIImage? {
        let fileUrl = destinationUrl(for: fotoAsset)

        return UIImage.fromRawThumbnail(locatedAt: fileUrl, targetSize: compressedPixelSize(pixelHeight: fotoAsset.pixelHeight, pixelWidth: fotoAsset.pixelWidth))
    }
    
    @available(*, deprecated, renamed: "thumbnail(for:)", message: "Use either a ReadOnly or an FFObjectID")
    nonisolated func thumbnail(for fotoAsset: FotoAsset) -> UIImage? {
        let objectId = typedID(fotoAsset)
        return thumbnail(for: objectId.getReadOnlyObject()!)
    }

    func imageResource(for workingSetAsset: WorkingSetFotoAsset, mediaType: PHAssetMediaType) async throws -> UIImage {
        switch mediaType {
        case .unknown:
            fatalError("Not supported for now")
        case .image:
            let resource = try await workingSetAsset.resource(for: .photo)
            let image = UIImage(contentsOfFile: resource.path())

            guard let image else {
                throw FilenFotoError.invalidImage
            }

            return image
        case .video:
            fatalError("Not supported for now")
        case .audio:
            fatalError("Not supported for now")
        @unknown default:
            fatalError("TODO: Fix this")
        }
    }
}
