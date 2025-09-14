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


private let thumbnailRootURL: URL = {
    let fileManager = FileManager.default
    let thumbnailDirectory = FileManager.photoThumbnailDirectory

    var isDirectoryPointer: ObjCBool = false
    if fileManager.fileExists(atPath: thumbnailDirectory.path(), isDirectory: &isDirectoryPointer) {
        if !isDirectoryPointer.boolValue {
            fatalError("A file exists at the thumbnail directory path, but it's not a directory.")  // TODO: Handle errors prettier!
        }
    } else {
        do {
            try fileManager.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Failed to create thumbnail directory: \(error)")  // TODO: Handle errors prettier!
        }
    }

    return thumbnailDirectory
}()

actor ThumbnailProviderActor {
    private var latestPendingThumbnailIndex: ThumbnailIndex {
        get {
            let rawValue = UserDefaults.standard.object(forKey: "latestPendingThumbnailIndex") as? Int64
            return ThumbnailIndex(rawValue: rawValue ?? 0)
        }

        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "latestPendingThumbnailIndex")
        }
    }

    func saveThumbnail(for compressedData: Data, to fotoAsset: FotoAsset) throws {
        let folderURL = thumbnailRootURL.appendingPathComponent(
            String(latestPendingThumbnailIndex.folderIndex)
        )

        let thumbnailURL = folderURL.appendingPathComponent(
            "\(latestPendingThumbnailIndex.thumbnailIndex).thumb"
        )

        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        try compressedData.write(to: thumbnailURL)
        
        fotoAsset.thumbnailIndex = latestPendingThumbnailIndex.rawValue
        latestPendingThumbnailIndex = latestPendingThumbnailIndex.incremented()
    }
}

class ThumbnailProvider: PhotoActionProviderDelegate {
    private init() {}
    static let shared = ThumbnailProvider()
    let thumbnailActor = ThumbnailProviderActor()
    
    func initiateProtocol(with fotoAsset: FotoAsset) async -> Bool {
        return false
    }
    
    func initiateProtocol(for photo: PHAsset, with fotoAsset: FotoAsset) async -> Bool {
        print("Initiate ThumbnailProvider for photo with identifier: \(fotoAsset.id)")

        let photoFile = PHAssetResource.assetResources(for: photo)
        let phAssetResourceManager = PHAssetResourceManager.default()
        for resource in photoFile {
            if resource.type == .photo {
                try! await phAssetResourceManager.writeData(for: resource, toFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test.jpg"), options: nil)
                let uiImage = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test.jpg").path)!
                
                try! await thumbnailActor.saveThumbnail(for: compressImageToJpeg(uiImage), to: fotoAsset)
            }
        }
        

        return true
    }

    func thumbnail(for fotoAsset: FotoAsset) -> UIImage? {
        let index = ThumbnailIndex(rawValue: fotoAsset.thumbnailIndex)
        
        let folderURL = thumbnailRootURL.appendingPathComponent(
            String(index.folderIndex)
        )

        let thumbnailURL = folderURL.appendingPathComponent(
            "\(index.thumbnailIndex).thumb"
        )

        guard FileManager.default.fileExists(atPath: thumbnailURL.path) else {
            return nil
        }
        
        return UIImage(contentsOfFile: thumbnailURL.path)
    }
    
    func compressedPixelSize(pixelHeight: Int64, pixelWidth: Int64) -> CGSize {
        let maxDimension: CGFloat = 200.0
        let size = CGSize(width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
        let aspectRatio = size.width / size.height
        
        let newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        return newSize
    }
    
    func compressImageToJpeg(_ image: UIImage) -> Data {
        let newSize = compressedPixelSize(pixelHeight: Int64(image.size.height), pixelWidth: Int64(image.size.width))
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage!.jpegData(compressionQuality: 0.8)!
    }


}
