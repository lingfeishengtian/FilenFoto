//
//  FFResourceCacheManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation
import CoreData
import CryptoKit

actor FFResourceCacheManager {
    static let shared = FFResourceCacheManager()
    
    private let photoCacheMaximumSize: UInt64 = 200 * 1024 * 1024
    private let photoCacheMaximumFileCount: Int = 1000
    
    private var currentSizeOfCache: UInt64 = 0
    
    private var fileMetadataCache: [String: Date] = [:]
    
    private init() {
        Task {
            await initializeCacheSize()
        }
    }
    
    private func initializeCacheSize() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: FileManager.photoCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: []
            )
            
            var totalSize: UInt64 = 0
            for fileURL in contents {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += UInt64(fileSize)

                    let fileName = fileURL.lastPathComponent
                    fileMetadataCache[fileName] = resourceValues.contentModificationDate ?? .distantPast
                }
            }
            
            currentSizeOfCache = totalSize
            evictFilesIfNeeded()
        } catch {
            currentSizeOfCache = 0
            fileMetadataCache.removeAll()
        }
    }
    
    /// Get the file path for a given RemoteResource
    private func getFilePath(for remoteResource: ReadOnlyNSManagedObject<RemoteResource>) -> URL {
        // Use existing fileURL function from RemoteResource extension
        return remoteResource.fileURL(in: FileManager.photoCacheDirectory)!
    }
    
    private func updateLastAccessDate(for fileName: String) {
        fileMetadataCache[fileName] = Date()
    }
    
    private func removeFile(at filePath: URL, fileSize: UInt64) {
        do {
            try FileManager.default.removeItem(at: filePath)
            currentSizeOfCache -= fileSize
            
            let fileName = filePath.lastPathComponent
            fileMetadataCache.removeValue(forKey: fileName)
        } catch {
            print("Failed to remove cached file \(filePath.path): \(error)")
        }
    }
    
    private func evictFilesIfNeeded() {
        guard currentSizeOfCache > photoCacheMaximumSize || fileMetadataCache.count > photoCacheMaximumFileCount else {
            return
        }
        
        var filesByAccessDate = fileMetadataCache.map { (fileName: $0.key, lastAccessDate: $0.value) }
            .sorted { $0.lastAccessDate < $1.lastAccessDate }
        
        while (currentSizeOfCache > photoCacheMaximumSize || fileMetadataCache.count > photoCacheMaximumFileCount) && !filesByAccessDate.isEmpty {
            let oldestFile = filesByAccessDate.removeFirst()
            
            let filePath = FileManager.photoCacheDirectory.appendingPathComponent(oldestFile.fileName)
            
            if let resourceValues = try? filePath.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                removeFile(at: filePath, fileSize: UInt64(fileSize))
            }
        }
    }
    
    /// Insert or update a cached resource using remoteResourceId
    /// - Parameters:
    ///   - remoteResourceId: The ID of the RemoteResource to cache
    ///   - fileUrl: The URL of the file to cache
    /// - Throws: If the operation fails
    func insert(remoteResourceId: String, fileUrl: URL) async throws {
        let cacheFileName = remoteResourceId
        let destinationPath = FileManager.photoCacheDirectory.appendingPathComponent(cacheFileName)
        
        // Get file size
        guard let fileSize = FileManager.default.sizeOfFile(at: fileUrl) else {
            throw FilenFotoError.invalidFile
        }
        
        // If this is an update, remove the old file first
        if FileManager.default.fileExists(atPath: destinationPath.path) {
            if let resourceValues = try? destinationPath.resourceValues(forKeys: [.fileSizeKey]),
               let oldFileSize = resourceValues.fileSize {
                currentSizeOfCache -= UInt64(oldFileSize)
            }
        }
        
        // Atomic write - copy to temporary location first, then move
        let tempPath = destinationPath.appendingPathExtension("tmp")
        
        do {
            try FileManager.default.copyItem(at: fileUrl, to: tempPath)
            
            // Move the temporary file to its final location
            try FileManager.default.moveItem(at: tempPath, to: destinationPath)
            
            // Update cache size and metadata
            currentSizeOfCache += UInt64(fileSize)
            updateLastAccessDate(for: cacheFileName)
            
            // Evict files if needed
            evictFilesIfNeeded()
        } catch {
            // Clean up the temporary file if something went wrong
            if FileManager.default.fileExists(atPath: tempPath.path) {
                try? FileManager.default.removeItem(at: tempPath)
            }
            throw error
        }
    }

    /// Insert using a typed Core Data object ID wrapper (`FFObjectID<T>`)
    func insert<T: NSManagedObject>(remoteResourceId: FFObjectID<T>, fileUrl: URL) async throws {
        let idString = remoteResourceId.raw.uriRepresentation().absoluteString
        try await insert(remoteResourceId: idString, fileUrl: fileUrl)
    }
    
    /// Insert or update a cached resource using RemoteResource
    /// - Parameters:
    ///   - remoteResource: The RemoteResource to cache
    ///   - fileUrl: The URL of the temporary file to cache
    /// - Throws: If the operation fails
    func insert(remoteResource: ReadOnlyNSManagedObject<RemoteResource>, fileUrl: URL) async throws {
        // Get the destination path using existing RemoteResource fileURL function
        let destinationPath = getFilePath(for: remoteResource)
        
        // Get file size
        guard let fileSize = FileManager.default.sizeOfFile(at: fileUrl) else {
            throw FilenFotoError.invalidFile
        }
        
        // If this is an update, remove the old file first
        if FileManager.default.fileExists(atPath: destinationPath.path) {
            if let resourceValues = try? destinationPath.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                currentSizeOfCache -= UInt64(fileSize)
            }
        }
        
        // Atomic write - copy to temporary location first, then move
        let tempPath = destinationPath.appendingPathExtension("tmp")
        
        do {
            try FileManager.default.copyItem(at: fileUrl, to: tempPath)
            
            // Move the temporary file to its final location
            try FileManager.default.moveItem(at: tempPath, to: destinationPath)
            
            // Update cache size and metadata
            currentSizeOfCache += UInt64(fileSize)
            updateLastAccessDate(for: destinationPath.lastPathComponent)
            
            // Evict files if needed
            evictFilesIfNeeded()
        } catch {
            // Clean up the temporary file if something went wrong
            if FileManager.default.fileExists(atPath: tempPath.path) {
                try? FileManager.default.removeItem(at: tempPath)
            }
            throw error
        }
    }
    
    /// Copy a cached resource to a destination folder
    /// - Parameters:
    ///   - remoteResourceId: The ID of the RemoteResource to copy from cache
    ///   - destination: The destination URL where the file should be copied
    /// - Returns: True if the operation succeeded, false otherwise
    func cacheOut(from remoteResourceId: String, to destination: URL) async -> Bool {
        let sourcePath = FileManager.photoCacheDirectory.appendingPathComponent(remoteResourceId)
        
        // Check if source file exists
        guard FileManager.default.fileExists(atPath: sourcePath.path) else {
            return false
        }
        
        do {
            // If destination exists, remove it first
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            
            // Copy the file from cache to destination
            try FileManager.default.copyItem(at: sourcePath, to: destination)
            
            // Update last access date
            updateLastAccessDate(for: remoteResourceId)
            
            return true
        } catch {
            print("Failed to copy cached file from \(sourcePath.path) to \(destination.path): \(error)")
            return false
        }
    }

    /// Copy a cached resource to a destination folder using a typed Core Data object ID wrapper
    func cacheOut<T: NSManagedObject>(from remoteResourceId: FFObjectID<T>, to destination: URL) async -> Bool {
        let idString = remoteResourceId.raw.uriRepresentation().absoluteString
        return await cacheOut(from: idString, to: destination)
    }
    
    /// Retrieve a cached resource for a RemoteResource
    /// - Parameter remoteResource: The RemoteResource to retrieve
    /// - Returns: The URL of the cached file, or nil if not found
    func retrieve(remoteResource: ReadOnlyNSManagedObject<RemoteResource>) async -> URL? {
        let filePath = getFilePath(for: remoteResource)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        // Update last access date
        updateLastAccessDate(for: filePath.lastPathComponent)
        
        return filePath
    }
    
    /// Remove a specific RemoteResource from cache
    /// - Parameter remoteResource: The RemoteResource to remove
    func remove(remoteResource: ReadOnlyNSManagedObject<RemoteResource>) async {
        let filePath = getFilePath(for: remoteResource)
        
        // Use modern resource values approach instead of deprecated attributesOfItem
        if let resourceValues = try? filePath.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = resourceValues.fileSize {
            removeFile(at: filePath, fileSize: UInt64(fileSize))
        }
    }
    
    /// Clear the entire cache
    func clearCache() async {
        do {
            try FileManager.default.clearDirectoryContents(at: FileManager.photoCacheDirectory)
            currentSizeOfCache = 0
            fileMetadataCache.removeAll()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    /// Get the current size of the cache
    /// - Returns: The current cache size in bytes
    func getCurrentCacheSize() -> UInt64 {
        return currentSizeOfCache
    }
    
    /// Check if a RemoteResource exists in cache
    /// - Parameter remoteResource: The RemoteResource to check
    /// - Returns: True if resource is cached, false otherwise
    func contains(remoteResource: ReadOnlyNSManagedObject<RemoteResource>) -> Bool {
        let filePath = getFilePath(for: remoteResource)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
}
