//
//  FFResourceManager+FilenActions.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import Foundation

extension FFResourceManager {
    func filenUpload(resource: FFObjectID<RemoteResource>, inCloudFolder filenResourceFolderUuid: String, inLocalFolder workingDirectory: URL) async throws {
        try await withTemporaryManagedObjectContext(resource) { resource in
            let filenClient = try PhotoContext.shared.unwrappedFilenClient()
            
            let pathToFile = resource.fileURL(in: workingDirectory)!
            
            let uploadedFile = try await filenClient.uploadFileFromPath(
                dirUuid: filenResourceFolderUuid,
                filePath: pathToFile.path(),
                fileName: UUID().uuidString
            )
            
            resource.filenUuid = UUID(uuidString: uploadedFile.uuid)
        }
    }
    
    func filenDelete(resource: FFObjectID<RemoteResource>, inLocalFolder workingDirectory: URL) async throws {
        try await withTemporaryManagedObjectContext(resource) { resource in
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
        }
    }
    
    func filenDownload(resource: ReadOnlyNSManagedObject<RemoteResource>, toLocalFolder workingDirectory: URL, cancellable: Bool) async throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()
        
        let destinationFilePath = resource.underlyingObject.fileURL(in: workingDirectory)
        
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
    
    func cancelDownload(resource: ReadOnlyNSManagedObject<RemoteResource>) throws {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()
        
        if let filenUuid = resource.filenUuid {
            filenClient.cancelDownload(uuid: filenUuid.uuidString)
        }
    }
}
