//
//  FileManager+Utilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation
import CryptoKit

let THUMBNAIL_FOLDER_ROOT = "FFThumbnailStore"
let PHOTO_CACHE_FOLDER_ROOT = "FFPhotoCache"
let WORKING_SET_FOLDER_ROOT = "FFWorkingSet"

// MARK: - App Directory Utilities
extension FileManager {
    // TODO: Maybe add a better way to handle errors?
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static let photoThumbnailDirectory = createAppDirectory(folderName: THUMBNAIL_FOLDER_ROOT)
    static let photoCacheDirectory = createAppDirectory(folderName: PHOTO_CACHE_FOLDER_ROOT)
    static let workingSetDirectory = createAppDirectory(folderName: WORKING_SET_FOLDER_ROOT)
    
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
    
    func clearDirectoryContents(at url: URL) throws {
        let contents = try self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        try contents.forEach(FileManager.default.removeItem(at:))
    }
}

// MARK: - Hashing Utilities
extension FileManager {
    static func getSHA256(forFile url: URL) throws -> SHA256.Digest {
        let handle = try FileHandle(forReadingFrom: url)
        var hasher = SHA256()

        let chunkSequence = sequence(state: handle) { handle in
            autoreleasepool {
                let data = handle.readData(ofLength: SHA256.blockByteCount)
                return data.isEmpty ? nil : data
            }
        }
        
        for chunk in chunkSequence {
            hasher.update(data: chunk)
        }

        try handle.close()
        return hasher.finalize()
    }
}

extension SHA256Digest {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}
