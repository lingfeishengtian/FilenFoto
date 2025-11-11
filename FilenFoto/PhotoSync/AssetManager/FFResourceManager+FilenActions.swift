//
//  FFResourceManager+FilenActions.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import Foundation

extension FFResourceManager {
    func filenCreateRootFolderIfNeeded(fotoAsset: FotoAsset) async throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()
        let rootPhotoDirectory = try PhotoContext.shared.unwrappedRootFolderDirectory()

        if fotoAsset.filenResourceFolderUuid == nil {
            // The asset's uuid is used for local identification purposes. Generating a new UUID here protects against the scenario where someone kills the application between creation of a directory and saving CoreData
            let directory = try await filenClient.createDirInDir(parentUuid: rootPhotoDirectory.uuidString, name: UUID().uuidString)
            fotoAsset.filenResourceFolderUuid = UUID(uuidString: directory.uuid)

            // After the folder is created in the cloud, immediately try to save the context
            await FFCoreDataManager.shared.saveContextIfNeeded()
        }
    }

    func filenUpload(resource: RemoteResource, inCloudFolder filenResourceFolderUuid: String, inLocalFolder workingDirectory: URL) async throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()

        let pathToFile = resource.fileURL(in: workingDirectory)!
                
        let uploadedFile = try await filenClient.uploadFileFromPath(
            dirUuid: filenResourceFolderUuid,
            filePath: pathToFile.path(),
            fileName: UUID().uuidString
        )

        resource.filenUuid = UUID(uuidString: uploadedFile.uuid)

        // After we finish uploading an asset, persist that change immediately
        await FFCoreDataManager.shared.saveContextIfNeeded()
    }

    func filenDelete(resource: RemoteResource, inLocalFolder workingDirectory: URL) async throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()

        let temporaryContext = FFCoreDataManager.shared.newChildContext()
        let resourceToDelete = temporaryContext.object(with: resource.objectID) as? RemoteResource

        guard let resourceToDelete else {
            throw FilenFotoError.coreDataContext
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

    func filenDownload(resource: RemoteResource, toLocalFolder workingDirectory: URL, cancellable: Bool) async throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()

        let destinationFilePath = resource.fileURL(in: workingDirectory)

        guard let destinationFilePath else {
            throw FilenFotoError.invalidFile
        }

        guard let filenUuid = resource.filenUuid else {
            throw FilenFotoError.remoteResourceNotFoundInFilen
        }

        if cancellable {
            try await filenClient.cancellableDownloadFileToPath(fileUuid: filenUuid.uuidString, path: destinationFilePath.path())
        } else {
            try await filenClient.downloadFileToPath(fileUuid: filenUuid.uuidString, path: destinationFilePath.path())
        }
    }
    
    func cancelDownload(resource: RemoteResource) throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()
        
        if let filenUuid = resource.filenUuid {
            filenClient.cancelDownload(uuid: filenUuid.uuidString)
        }
    }
}
