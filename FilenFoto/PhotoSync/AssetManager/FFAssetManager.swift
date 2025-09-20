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

enum FFAssetManagerError: Error {
    case resourcesLeftOverAfterFetch
    case contextError
}

class FFAssetManager {
    let logger = Logger(subsystem: Bundle.main.bundlePath, category: "FFAssetManager")

    private func validate(remoteResources: [RemoteResource], existIn workingDirectory: URL) -> Bool {
        let contentsOfWorkingDirectory = (try? FileManager.default.contentsOfDirectory(at: workingDirectory, includingPropertiesForKeys: .none)) ?? []

        for remoteResource in remoteResources {
            if !contentsOfWorkingDirectory.contains(remoteResource.fileURL(in: workingDirectory)!) {
                return false
            }
        }

        return true
    }

    /// Fetches assets for the given FotoAsset from the iOS Photo asset and writes to the specified destination folder. Throws if context generation fails.
    ///
    /// - Returns: Whether or not a remote sync to the cloud service provider is required.
    func fetchAssets(for parentContextFotoAsset: FotoAsset, from iosPhotoAsset: PHAsset, writeTo destinationFolder: URL) async throws
        -> WorkingAssetState
    {
        // Get a temporary context, just in case the app exits in the middle of the operation, we do not write the broken contents to disk
        let tempContext = FFCoreDataManager.shared.newChildContext()
        let fotoAsset = tempContext.object(with: parentContextFotoAsset.objectID) as! FotoAsset

        let assetResources = PHAssetResource.assetResources(for: iosPhotoAsset)
        let existingRemoteResourcesCount = fotoAsset.remoteResources?.count ?? 0

        // TODO: I don't think this logic should be in this function. Move this out to the working set class
        if existingRemoteResourcesCount > 0 {
            let wasAssetModified = iosPhotoAsset.modificationDate != parentContextFotoAsset.dateModified
            let numberOfResourcesOnCloud = fotoAsset.remoteResourcesArray.filter({ $0.filenUuid != nil }).count
            
            let hasAllResourcesUploaded = existingRemoteResourcesCount == numberOfResourcesOnCloud
            let doResourceCountsMismatch = assetResources.count != existingRemoteResourcesCount

            let doPreviouslyPulledResourcesExist = validate(remoteResources: fotoAsset.remoteResourcesArray, existIn: destinationFolder)

            if wasAssetModified || doResourceCountsMismatch {
                for resource in fotoAsset.remoteResourcesArray {
                    resource.isMarkedForDeletion = true
                }
            } else {
                switch (hasAllResourcesUploaded, doPreviouslyPulledResourcesExist) {
                case (true, true):
                    return .alreadySynced
                case (true, false):
                    return .needsDownloadFromCloud
                case (false, true):
                    return .needsSync
                case (false, false):
                    logger.error("Error state occurred in asset \(iosPhotoAsset.localIdentifier), resetting resources")
                    
                    for resource in fotoAsset.remoteResourcesArray {
                        resource.isMarkedForDeletion = true
                    }
                }
            }
        }

        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        try FileManager.default.clearDirectoryContents(at: destinationFolder)

        for assetResource in assetResources {
            let remoteResource = RemoteResource(context: tempContext)
            remoteResource.uuid = UUID()
            remoteResource.assetResourceType = assetResource.type
            remoteResource.originalFilename = assetResource.originalFilename
            remoteResource.parentAsset = fotoAsset

            let destinationFileUrl = remoteResource.fileURL(in: destinationFolder)!

            try await PHAssetResourceManager.default().writeData(
                for: assetResource,
                toFile: destinationFileUrl,
                options: nil
            )

            remoteResource.fileHashBinary = Data(try FileManager.getSHA256(forFile: destinationFileUrl))
        }

        try tempContext.save()
        await FFCoreDataManager.shared.saveContextIfNeeded()

        return .needsSync
    }

    /// Syncs resources from working directory with the remoteResources. Delete resources marked for deletion and upload new resources
    func syncResources(in workingDirectory: URL, for fotoAsset: FotoAsset) async throws {
        let sharedPhotoContext = PhotoContext.shared
        let filenClient = try sharedPhotoContext.unwrappedFilenClient()
        let rootPhotoDirectory = try sharedPhotoContext.unwrappedRootFolderDirectory()

        let remoteResources = fotoAsset.remoteResourcesArray

        if fotoAsset.filenResourceFolderUuid == nil {
            // The asset's uuid is used for local identification purposes. Generating a new UUID here protects against the scenario where someone kills the application between creation of a directory and saving CoreData
            let directory = try await filenClient.createDirInDir(parentUuid: rootPhotoDirectory.uuidString, name: UUID().uuidString)
            fotoAsset.filenResourceFolderUuid = UUID(uuidString: directory.uuid)

            // After the folder is created in the cloud, immediately try to save the context
            await FFCoreDataManager.shared.saveContextIfNeeded()
        }

        let filenResourceFolderUuidString = fotoAsset.filenResourceFolderUuid!.uuidString
        let stagedRemoteResourcesToUpload = remoteResources.filter { $0.filenUuid == nil }
        let stagedRemoteResourcesToDelete = remoteResources.filter { $0.isMarkedForDeletion }

        if stagedRemoteResourcesToUpload.isEmpty && stagedRemoteResourcesToDelete.isEmpty {
            logger.info("No new files to upload or delete for asset with uuid: \(fotoAsset.uuid!.uuidString)")
            return
        }

        for resourceToUpload in stagedRemoteResourcesToUpload {
            let pathToFile = resourceToUpload.fileURL(in: workingDirectory)!
            print("Trying to upload \(pathToFile.path())")
            let uploadedFile = try await filenClient.uploadFileFromPath(
                dirUuid: filenResourceFolderUuidString,
                filePath: pathToFile.path(),
                fileName: UUID().uuidString
            )

            resourceToUpload.filenUuid = UUID(uuidString: uploadedFile.uuid)

            // After we finish uploading an asset, persist that change immediately
            await FFCoreDataManager.shared.saveContextIfNeeded()
        }

        for resourceToDeleteParentContext in stagedRemoteResourcesToDelete {
            print("Trying to delete \(resourceToDeleteParentContext.originalFilename)")
            let temporaryContext = FFCoreDataManager.shared.newChildContext()
            let resourceToDelete = temporaryContext.object(with: resourceToDeleteParentContext.objectID) as? RemoteResource

            guard let resourceToDelete else {
                throw FFAssetManagerError.contextError
            }

            let pathToFile = resourceToDelete.fileURL(in: workingDirectory)

            if let filenUuid = resourceToDelete.filenUuid {
                try await filenClient.deleteFile(fileUuid: filenUuid.uuidString)
            }

            resourceToDelete.filenUuid = nil

            // The file might not even exist, so don't error out when deleting
            if let pathToFile {
                try? FileManager.default.removeItem(at: pathToFile)
            }

            // Need to push to parent before deleting or else it causes validation errors
            try temporaryContext.save()

            temporaryContext.delete(resourceToDelete)
            try temporaryContext.save()

            await FFCoreDataManager.shared.saveContextIfNeeded()
        }
    }

    // TODO: Validate sync status (filen folder and file contents exist?)
    // TODO: Vaildate file hashes (after they're downloaded into the working set)
}
