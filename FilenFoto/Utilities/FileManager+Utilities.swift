//
//  FileManager+Utilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation

let THUMBNAIL_FOLDER_ROOT = "FFThumbnailStore"
let PHOTO_CACHE_FOLDER_ROOT = "FFPhotoCache"

// MARK: - App Directory Utilities
extension FileManager {
    // TODO: Maybe add a better way to handle errors?
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static let photoThumbnailDirectory = createAppDirectory(folderName: THUMBNAIL_FOLDER_ROOT)
    static let photoCacheDirectory = createAppDirectory(folderName: PHOTO_CACHE_FOLDER_ROOT)
    
    static func createAppDirectory(folderName: String) -> URL {
        let folder = FileManager.default.documentsDirectory.appendingPathComponent(folderName)
        
        do {
            try FileManager.default.createFolderIfNeeded(at: folder)
        } catch {
            // TODO: Better error handling
            fatalError("Failed to create app directory: \(error)")
        }
        
        return folder
    }
}

// MARK: - File/Directory Utilities

extension FileManager {
    func sizeOfFile(at url: URL) -> Int64? {
        guard url.isFileURL else {
            return nil
        }
        
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? NSNumber {
                return fileSize.int64Value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func createFolderIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
