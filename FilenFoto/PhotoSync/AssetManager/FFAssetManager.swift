//
//  FFAssetManager.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/15/25.
//

import CoreData
import Foundation
import Photos
import os.log

class FFAssetManager {
    let logger = Logger(subsystem: Bundle.main.bundlePath, category: "FFAssetManager")

    func generateTempChildContext() throws -> NSManagedObjectContext {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = FFCoreDataManager.shared.backgroundContext

        return managedContext
    }

    /// Fetches assets for the given FotoAsset from the iOS Photo asset and writes to the specified destination folder. Throws if context generation fails.
    func fetchAssets(for fotoAsset: FotoAsset, from iosPhotoAsset: PHAsset, writeTo destinationFolder: URL) async throws {
        // Get a temporary context, just in case the app exits in the middle of the operation, we do not write the broken contents to disk
        let tempContext = try generateTempChildContext()
        // *DO NOT* access any properties or else it will fault the child context
        let temporaryFotoAssetFromChildContext = tempContext.object(with: fotoAsset.objectID)

        let assetResources = PHAssetResource.assetResources(for: iosPhotoAsset)
        let existingRemoteResourcesCount = fotoAsset.remoteResources?.count ?? 0

        if existingRemoteResourcesCount > 0 {
            logger.info(
                "Asset resources for \(iosPhotoAsset.localIdentifier) already exist, skipping fetch."
            )

            // TODO: Validate asset resources

            return
        }

        try FileManager.default.clearDirectoryContents(at: destinationFolder)

        for assetResource in assetResources {
            let remoteResource = RemoteResource(context: tempContext)
            remoteResource.uuid = UUID()
            remoteResource.assetResourceType = assetResource.type
            remoteResource.originalFilename = assetResource.originalFilename
            remoteResource.parentAsset = temporaryFotoAssetFromChildContext as? FotoAsset

            let destinationFileUrl = destinationFolder.appendingPathComponent(remoteResource.uuid!.uuidString)

            try await PHAssetResourceManager.default().writeData(
                for: assetResource,
                toFile: destinationFileUrl,
                options: nil
            )

            remoteResource.fileHashBinary = Data(try FileManager.getSHA256(forFile: destinationFileUrl))
        }

        try tempContext.save()
    }

    func uploadAssets(in workingDirectory: URL, for fotoAsset: FotoAsset) async throws {
        let sharedPhotoContext = PhotoContext.shared
        let filenClient = try sharedPhotoContext.unwrappedFilenClient()
        let rootPhotoDirectory = try sharedPhotoContext.unwrappedRootFolderDirectory()

        if fotoAsset.filenResourceFolderUuid == nil {
            // The asset's uuid is used for local identification purposes. Generating a new UUID here protects against the scenario where someone kills the application between creation of a directory and saving CoreData
            let directory = try await filenClient.createDirInDir(parentUuid: rootPhotoDirectory.uuidString, name: UUID().uuidString)
            fotoAsset.filenResourceFolderUuid = UUID(uuidString: directory.uuid)
        }

        let filenResourceFolderUuidString = fotoAsset.filenResourceFolderUuid!.uuidString
        let remoteResources = fotoAsset.remoteResources?.allObjects as? [RemoteResource] ?? []
        let stagedRemoteResourcesToUpload = remoteResources.filter { $0.filenUuid == nil }

        for resourceToUpload in stagedRemoteResourcesToUpload {
            let pathToFile = workingDirectory.appending(path: resourceToUpload.uuid!.uuidString)
            let uploadedFile = try await filenClient.uploadFileFromPath(
                dirUuid: filenResourceFolderUuidString,
                filePath: pathToFile.path(),
                fileName: UUID().uuidString
            )
            
            resourceToUpload.filenUuid = UUID(uuidString: uploadedFile.uuid)
            
            try FFResourceCacheManager.shared.insert(remoteResource: resourceToUpload, fileUrl: pathToFile)
        }
        
        // TODO: Delete the working folder after we validate that there are no files left
    }
}
