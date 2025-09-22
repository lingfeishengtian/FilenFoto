//
//  ThumbnailProvider+FileUtilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/22/25.
//

import Foundation
import UIKit

extension ThumbnailProvider {
    /// Assumes fotoAsset already has a UUID
    func destinationUrl(for fotoAsset: FotoAsset) -> URL {
        let thumbnailIndex = fotoAsset.thumbnailIndex
        let directory = thumbnailIndex.directory(rootDirectory: FileManager.photoThumbnailDirectory)
        
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        return directory.appending(path: fotoAsset.uuid!.uuidString)
    }
    
    func storeThumbnail(_ data: Data, for fotoAsset: FotoAsset) throws {
        try data.write(to: destinationUrl(for: fotoAsset))
    }
    
    func thumbnail(for fotoAsset: FotoAsset) -> UIImage? {
        let fileUrl = destinationUrl(for: fotoAsset)
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            return UIImage(contentsOfFile: fileUrl.path)
        }
        
        return nil
    }
}
