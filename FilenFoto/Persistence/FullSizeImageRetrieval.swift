//
//  FullSizeImageCache.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/16/24.
//

import Foundation
import Photos
import os
import SwiftUI

class FullSizeImageCache {
    static let shared = FullSizeImageCache()
    
    static let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "FullSizeImageCache")
    
    @AppStorage("maxCacheSize") var maxCacheSize: CacheSizeValues = .一GB
    static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    static func doesIdExistInCache(for id: Int) -> Bool {
        return FileManager.default.fileExists(atPath: getURLForIdInCache(for: id).path)
    }
    
    private static func getURLForIdInCache(for id: Int) -> URL {
        return cacheDirectory.appending(path: String(id))
    }
    
    static func getFullSizeImageOrThumbnail(for asset: DBPhotoAsset) -> URL {
        let thumbnailURL = asset.thumbnailURL
        
        var fullsize = PhotoDatabase.shared.getFilenUUID(for: asset, mediaType: .fullSizePhoto)
        let regular = PhotoDatabase.shared.getFilenUUID(for: asset, mediaType: .photo)

        fullsize.append(contentsOf: regular)
        
        if fullsize.count > 0 {
            let file = getURLForIdInCache(for: Int(fullsize.first!.id)).appendingPathExtension(fullsize.first!.resourceExtension)
            if FileManager.default.fileExists(atPath: file.path) {
                return file
            }
        }
        
        return thumbnailURL
    }
    
    static func deleteOldestFilesInCache(untilFolderSizeIsUnder limitMB: Int) {
        deleteOldestFiles(in: cacheDirectory.path, untilFolderSizeIsUnder: limitMB)
    }
    
    static private func deleteOldestFiles(in folderPath: String, untilFolderSizeIsUnder limitMB: Int) {
        if limitMB < 0 {
            return
        }
        
        let fileManager = FileManager.default
        let limitBytes = Int64(limitMB) * 1024 * 1024
        
        do {
            // Get all files in the folder
            let files = try fileManager.contentsOfDirectory(atPath: folderPath)
            
            // Build a list of file URLs with their attributes (like creation date)
            var fileURLs: [(url: URL, attributes: [FileAttributeKey: Any])] = []
            for file in files {
                let fileURL = URL(fileURLWithPath: folderPath).appendingPathComponent(file)
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                fileURLs.append((url: fileURL, attributes: attributes))
            }
            
            // Sort files by creation date, oldest first
            fileURLs.sort { ($0.attributes[.creationDate] as! Date) < ($1.attributes[.creationDate] as! Date) }
            
            // Calculate total folder size
            var folderSize: Int64 = 0
            for file in fileURLs {
                if let fileSize = file.attributes[.size] as? Int64 {
                    folderSize += fileSize
                }
            }
            
            // Delete oldest files until folder size is under the limit
            for file in fileURLs {
                if folderSize <= limitBytes {
                    break
                }
                
                if let fileSize = file.attributes[.size] as? Int64 {
                    do {
                        try fileManager.removeItem(at: file.url)
                        folderSize -= fileSize
                        print("Deleted: \(file.url.lastPathComponent), Size: \(fileSize / 1024) KB")
                    } catch {
                        print("Failed to delete file: \(file.url.lastPathComponent), error: \(error)")
                    }
                }
            }
            
            print("Folder size is now under the limit: \(Double(folderSize) / (1024 * 1024)) MB")
        } catch {
            print("Error accessing folder: \(error)")
        }
    }

    
    static func downloadResourceInCache(for resource: PhotoDatabase.DBPhotoResourceResult) async -> String? {
        guard let filenClient = getFilenClientWithUserDefaultConfig() else {
            logger.error("Filen Client not initialized")
            return nil
        }
        
        deleteOldestFiles(in: cacheDirectory.path, untilFolderSizeIsUnder: FullSizeImageCache.shared.maxCacheSize.rawValue)
        
        do {
            // TODO: Handle file doesn't exist
            let downloadTo = getURLForIdInCache(for: Int(resource.id)).appendingPathExtension(resource.resourceExtension).path
            
            // exists in cache?
            if FileManager.default.fileExists(atPath: downloadTo) {
                /// If sha of stored file is incorrect, delete it and redownload
                if try getSHA256(forFile: URL(filePath: downloadTo)) == resource.sha256 {
                    return downloadTo
                } else {
                    try FileManager.default.removeItem(atPath: downloadTo)
                    return await downloadResourceInCache(for: resource)
                }
            } else {
                let (didDownload, url) = try await filenClient.downloadFile(fileGetResponse: try await filenClient.fileInfo(uuid: resource.uuid), url: downloadTo)
                if !didDownload {
                    logger.error("Failed to download at \(url)")
                }
                return url
            }
        } catch {
            logger.error("Encountered error \(error)")
            return nil
        }
    }
}

class FullSizeImageRetrieval {
    static let shared = FullSizeImageRetrieval()
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "FullSizeImageRetrieval")

    func downloadResources(for asset: DBPhotoAsset, resourceTypes: [PHAssetResourceType]) async -> [PHAssetResourceType : [(URL, String)]] {
        var resultingDownloads = [PHAssetResourceType : [(URL, String)]]()
        for resourceType in resourceTypes {
            let uuids = PhotoDatabase.shared.getFilenUUID(for: asset, mediaType: resourceType)
            var urls = [(URL, String)]()
            for uuid in uuids {
                // TODO: Handle file doesn't exist
//                if !FullSizeImageCache.doesIdExistInCache(for: Int(uuid.id)) {
//                    if !(await FullSizeImageCache.downloadResourceInCache(for: uuid)) {
//                        logger.log("Not continuing since resource failed to download")
//                        continue
//                    }
//                }
//                
//                urls.append(FullSizeImageCache.getURLForIdInCache(for: Int(uuid.id)))
                if let successfullyDownloaded = await FullSizeImageCache.downloadResourceInCache(for: uuid) {
                    urls.append((URL(filePath: successfullyDownloaded), uuid.sha256))
                } else {
                    logger.log("Not continuing since resource failed to download")
                }
            }
            
            resultingDownloads[resourceType] = urls
        }
        return resultingDownloads
    }
    
    func getLiveImageResources(asset: DBPhotoAsset) async -> (photoUrl: URL, videoUrl: URL)? {
        if !asset.mediaSubtype.contains(.photoLive) {
            return nil
        }
        
        // TODO: use FullSize if exists
        let videoResource: PHAssetResourceType = .pairedVideo
        let imageResource: PHAssetResourceType = .photo
        
        let resourcesToGet: [PHAssetResourceType] = [videoResource, imageResource]
        let downlaodResources = await downloadResources(for: asset, resourceTypes: resourcesToGet)
        
        if let firstPhotoURL = downlaodResources[imageResource]?.first, let firstVideoURL = downlaodResources[videoResource]?.first {
            do {
                let photoHash = try getSHA256(forFile: firstPhotoURL.0)
                let videoHash = try getSHA256(forFile: firstVideoURL.0)
                
                if photoHash != firstPhotoURL.1 || videoHash != firstVideoURL.1 {
                    logger.error("Downloaded resources are not equal to original")
                    return nil
                }
                
                
                return (photoUrl: firstPhotoURL.0, videoUrl: firstVideoURL.0)
            } catch {
                logger.error("\(error)")
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    func getImageResource(asset: DBPhotoAsset) async -> URL? {
        let imageResource: PHAssetResourceType = .photo
        let resourcesToGet: [PHAssetResourceType] = [imageResource]
        let downlaodResources = await downloadResources(for: asset, resourceTypes: resourcesToGet)
        
        do {
            // Validate SHA256
            if let assetURL = downlaodResources[imageResource]?.first {
                let sha256 = try getSHA256(forFile: assetURL.0)
                
                if sha256 == assetURL.1 {
                    return downlaodResources[imageResource]?.first?.0
                } else {
                    logger.error("Hash mismatch")
                }
            }
        } catch {
            logger.error("\(error)")
            return nil
        }
        
        return nil
    }
    
    func getVideoResource(asset: DBPhotoAsset) async -> URL? {
        let resourcesToGet: [PHAssetResourceType] = [.video]
        let downlaodResources = await downloadResources(for: asset, resourceTypes: resourcesToGet)
        
        do {
            // Validate SHA256
            if let assetURL = downlaodResources[.video]?.first {
                let sha256 = try getSHA256(forFile: assetURL.0)
                
                if sha256 == assetURL.1 {
                    return downlaodResources[.video]?.first?.0
                } else {
                    logger.error("Hash mismatch")
                }
            }
        } catch {
            logger.error("\(error)")
            return nil
        }
        
        return nil
    }
    
    static func isMediaSubtypeImage(_ mediaSubtype: PHAssetMediaSubtype) -> Bool {
        // TODO: Include regular iamge
        return mediaSubtype.contains(.photoHDR) ||
        mediaSubtype.contains(.photoPanorama) ||
        mediaSubtype.contains(.photoScreenshot) ||
        mediaSubtype.contains(.photoDepthEffect)
    }
}
