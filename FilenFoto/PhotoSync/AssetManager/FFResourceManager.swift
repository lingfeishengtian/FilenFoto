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

class FFResourceManager {
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

        let assetRequestOptions = PHAssetResourceRequestOptions()
        assetRequestOptions.isNetworkAccessAllowed = true
        
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
                options: assetRequestOptions
            )

            remoteResource.fileHashBinary = Data(try FileManager.getSHA256(forFile: destinationFileUrl))
        }

        try tempContext.save()
        await FFCoreDataManager.shared.saveContextIfNeeded()

        return .needsSync
    }

    /// Syncs resources from working directory with the remoteResources. Delete resources marked for deletion and upload new resources
    func syncResources(in workingDirectory: URL, for fotoAsset: FotoAsset) async throws {
        let remoteResources = fotoAsset.remoteResourcesArray

        try await filenCreateRootFolderIfNeeded(fotoAsset: fotoAsset)

        let filenResourceFolderUuidString = fotoAsset.filenResourceFolderUuid!.uuidString
        let stagedRemoteResourcesToUpload = remoteResources.filter { $0.filenUuid == nil && $0.isMarkedForDeletion == false }
        let stagedRemoteResourcesToDelete = remoteResources.filter { $0.isMarkedForDeletion }

        if stagedRemoteResourcesToUpload.isEmpty && stagedRemoteResourcesToDelete.isEmpty {
            logger.info("No new files to upload or delete for asset with uuid: \(fotoAsset.uuid!.uuidString)")
            return
        }
        
        for resourceToUpload in stagedRemoteResourcesToUpload {
            try await filenUpload(resource: resourceToUpload, inCloudFolder: filenResourceFolderUuidString, inLocalFolder: workingDirectory)
        }

        for resourceToDeleteParentContext in stagedRemoteResourcesToDelete {
            try await filenDelete(resource: resourceToDeleteParentContext, inLocalFolder: workingDirectory)
        }
    }

    // TODO: Validate sync status (filen folder and file contents exist?)
    // TODO: Vaildate file hashes (after they're downloaded into the working set)
}
