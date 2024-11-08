//
//  FilenSync.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/5/24.
//

import Foundation
import FilenSDK
import os
import SQLite

class FilenSync : ProgressCheckingPhotoSyncProtocol {
    var filenClient: FilenClient? = nil
    private let syncDatabase: FileSyncDatabase
    private let folderUUID: String
    private var countOfPhotos = 0
    private let logger = Logger(subsystem: "com.filen.filenfoto", category: "FilenSync")
    private let maxConcurrentThreads = 4
    @Published private var failedFileStatuses = [FailedStatus]()
    private var failedStatusesDatabaseStream: RowIterator?
    
    var dbFilePath: URL {
        return syncDatabase.dbFilePath
    }
    
    init(folderUUID: String) {
        filenClient = getFilenClientWithUserDefaultConfig()
        self.folderUUID = folderUUID
        self.syncDatabase = FileSyncDatabase(uuid: folderUUID)
    }
    
    func getTotalNumberOfPhotos() -> Int {
        return countOfPhotos
    }
    
    /// Newly added failed statuses will not be added
    var failedImports: [FailedStatus] {
#if targetEnvironment(simulator)
//        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//            var ret = [FailedStatus]()
//            for i in 0..<100 {
//                ret.append(FailedStatus(fileUUID: "UUID\(i)", fileName: "File\(i)File\(i)File\(i)File\(i)File\(i)", statusMessage: "Failed \(i)"))
//            }
//            return ret
//        }
#endif
        if failedStatusesDatabaseStream == nil {
            failedStatusesDatabaseStream = syncDatabase.failedImportStream()
            addMoreFailedImportsFromStream()
        }
        
        return failedFileStatuses
    }
    
    func addMoreFailedImportsFromStream() {
        var cnt = 20
        while cnt > 0 {
            if let failedStatus = try? failedStatusesDatabaseStream?.failableNext() {
                failedFileStatuses.append(FailedStatus(fileUUID: failedStatus[failedFileUUID], fileName: failedStatus[failedFileName], statusMessage: failedStatus[failedStatusMessage]))
                cnt -= 1
            } else {
                break
            }
        }
    }
    
    /// Non recursive
    func queuePhotosToDownload() async throws {
        if filenClient == nil {
            filenClient = getFilenClientWithUserDefaultConfig()
        }
        
        guard let filenClient else {
            logger.error("Filen client cannot be found")
            return
        }
        
        let pulledFolderInfo = try await filenClient.dirContent(uuid: folderUUID)
        for upload in pulledFolderInfo.uploads {
            do {
                syncDatabase.insertFile(filenUUID: upload.uuid, fileName: try filenClient.decryptFileName(metadata: upload.metadata))
            } catch {
                logger.warning("Could not insert file \(upload.uuid) to database")
                fileFailure(filenFile: FilenFile(filenUUID: upload.uuid, fileName: (try? filenClient.decryptFileName(metadata: upload.metadata)) ?? ""), message: "File queuing failed")
            }
        }
        
        syncDatabase.finishPotentialImport()
    }
    
    var currentFileNames = [String]()
    
    // TODO: Add this to the protocol
    var syncProgress: SyncProgressInfo? = nil
    
    func startSync(onComplete: @escaping () -> Void, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void, progressInfo: SyncProgressInfo) {
        syncProgress = progressInfo
        cleanTmpDirectory()
        Task {
            if filenClient == nil {
                filenClient = getFilenClientWithUserDefaultConfig()
            }
            
            guard let filenClient else {
                onComplete()
                logger.error("Filen client cannot be found")
                return
            }
            
            let returnedFiles = try await filenClient.dirContent(uuid: filenPhotoFolderUUID!)
            currentFileNames = []
            for file in returnedFiles.uploads {
                let dirFiles = try filenClient.decryptFileName(metadata: file.metadata)
                currentFileNames.append(dirFiles)
            }
            
            if syncDatabase.getStatus() == .started {
                do {
                    try await queuePhotosToDownload()
                } catch {
                    onComplete()
                    logger.error("Could not queue photos to download \(error)")
                    return
                }
            }
            
            let total = syncDatabase.getTotalFileCount()
            syncProgress?.setMaxImages(maxImages: total, updateProgress: true)
            self.countOfPhotos = syncDatabase.getUnimportedFileCount()
            syncProgress?.overrideFinished(count: total - countOfPhotos)
            let unimportedFileStreamer = syncDatabase.getUnimportedFiles()
            
            await withTaskGroup(of: Void.self) { group in
                var count = 0
                
                while let file = unimportedFileStreamer.next() {
                    if count >= maxConcurrentThreads {
                        await group.next()
                    }
                    
                    count += 1
                    group.addTask {
                        await self.downloadAndIdentifyPhoto(file, onNewDatabasePhotoAdded: onNewDatabasePhotoAdded)
                    }
                }
            }
            onComplete()
        }
    }
    
    @inline(__always) private func fileFailure(filenFile: FilenFile, message: String) {
        logger.error("File \(filenFile.filenUUID) failed with message \(message)")
        syncDatabase.insertFailedStatus(failStatus: FailedStatus(fileUUID: filenFile.filenUUID, fileName: filenFile.fileName, statusMessage: message))
        syncDatabase.finishImport(filenUUID: filenFile.filenUUID)
        syncProgress?.updateImageProgress(progress: 1.0, message: message, localIdentifier: filenFile.filenUUID)
    }
    
    let thumbnailsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("thumbnails", conformingTo: .folder)

    func downloadAndIdentifyPhoto(_ filenFile: FilenFile, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void) async {
        syncProgress?.addImage(localIdentifier: filenFile.filenUUID)
        syncProgress?.updateImageProgress(progress: 0.0, message: "Downloading \(filenFile.filenUUID)", localIdentifier: filenFile.filenUUID)
        let fileInfo = try? await filenClient?.fileInfo(uuid: filenFile.filenUUID)
        guard let fileInfo else {
            fileFailure(filenFile: filenFile, message: "Could not get file info")
            return
        }
        
//        let tmpFileUrl = FileManager.default.temporaryDirectory.appending(component: filenFile.fileName, directoryHint: .notDirectory)
        var fileName = filenFile.fileName
        while self.currentFileNames.contains(fileName) {
            fileName = UUID().uuidString + fileName
        }
        let tmpLocation = FileManager.default.temporaryDirectory.appending(path: fileName)
        
        let downloadResults = try? await filenClient?.downloadFile(fileGetResponse: fileInfo, url: tmpLocation.path)
        
        guard let downloadResults, downloadResults.didDownload else {
            fileFailure(filenFile: filenFile, message: "Could not download file")
            return
        }
        
        guard let extractedImageDetails = try? await imageNameExifExtractor(url: tmpLocation) else {
            fileFailure(filenFile: filenFile, message: "Could not extract image details")
            return
        }
        
        guard let assetId = try? localIdentifier(dbExtractedAsset: extractedImageDetails, originalFilename: filenFile.fileName) else {
            fileFailure(filenFile: filenFile, message: "Could not insert asset into database")
            return
        }
        
        guard let uploadFileResults = try? await filenClient?.uploadFile(url: tmpLocation.path, parent: filenPhotoFolderUUID!) else {
            fileFailure(filenFile: filenFile, message: "Could not upload file")
            return
        }
        
        if !FileManager.default.fileExists(atPath: self.thumbnailsDirectory.path) {
            try? FileManager.default.createDirectory(at: self.thumbnailsDirectory, withIntermediateDirectories: true)
        }
        
        // TODO: Make this code better
        if photoResourceTypes.contains(extractedImageDetails.resourceType) {
            ImageVision.classifyAndTextRecognize(image: tmpLocation, completionHandler: { obs, err in
                if let err = err {
                    self.fileFailure(filenFile: filenFile, message: "Could not classify image \(err)")
                    return
                } else {
                    Task {
                        let compressedThumbnailUrl = self.thumbnailsDirectory.appendingPathComponent(tmpLocation.lastPathComponent, conformingTo: .jpeg)
                        
                        do {
                            try await ImageCompressor.compressImage(from: tmpLocation, outputDestination: compressedThumbnailUrl)
                            let result = PhotoDatabase.shared.insertPhoto(asset: extractedImageDetails, filenUUID: uploadFileResults.uuid, fileName: filenFile.fileName, assetRowId: assetId, imageClassificationResults: obs!.0, textResultClassificationResults: obs!.1, thumbnailLocation: compressedThumbnailUrl)
                            self.handleInsertResult(result: result, onNewDatabasePhotoAdded: onNewDatabasePhotoAdded, filenFile: filenFile)
                            
                            self.syncDatabase.finishImport(filenUUID: filenFile.filenUUID)
                            try FileManager.default.removeItem(at: tmpLocation)
                        } catch {
                            self.fileFailure(filenFile: filenFile, message: "Could not insert photo into database \(error)")
                            return
                        }
                    }
                }
            })
        } else {
            ImageVision.classifyAndTextRecognize(video: tmpLocation, completionHandler: { res, err in
                if let err = err {
                    self.fileFailure(filenFile: filenFile, message: "Could not classify video \(err)")
                    return
                } else {
                    Task {
                        let compressedThumbnailUrl = self.thumbnailsDirectory.appendingPathComponent(tmpLocation.lastPathComponent, conformingTo: .jpeg)
                        
                        do {
                            try await ImageCompressor.compressImage(from: res!.generatedCGImage, outputDestination: compressedThumbnailUrl)
                            let result = PhotoDatabase.shared.insertPhoto(asset: extractedImageDetails, filenUUID: filenFile.filenUUID, fileName: filenFile.fileName, assetRowId: assetId, imageClassificationResults: res!.photoRecog.0, textResultClassificationResults: res!.photoRecog.1, thumbnailLocation: compressedThumbnailUrl)
                            self.handleInsertResult(result: result, onNewDatabasePhotoAdded: onNewDatabasePhotoAdded, filenFile: filenFile)
                            
                            self.syncDatabase.finishImport(filenUUID: filenFile.filenUUID)
                            try FileManager.default.removeItem(at: tmpLocation)
                        } catch {
                            self.fileFailure(filenFile: filenFile, message: "Could not insert photo into database \(error)")
                            return
                        }
                    }
                }
            })
        }
    }
    
    func handleInsertResult(result: PhotoDatabase.InsertPhotoResult, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void, filenFile: FilenFile) {
        switch result {
        case .success(let dbPhotoAsset, let shouldCallNewPhotoAdded):
            if shouldCallNewPhotoAdded {
                onNewDatabasePhotoAdded(dbPhotoAsset)
            }
            syncProgress?.updateImageProgress(progress: 1.0, message: "Imported \(filenFile.filenUUID)", localIdentifier: filenFile.filenUUID)
        case .failed:
            syncProgress?.updateImageProgress(progress: 1.0, message: "Failed to import \(filenFile.filenUUID)", localIdentifier: filenFile.filenUUID)
        case .exists:
            fatalError("Should not exist")
        }
    }
        
    
    let syncDispatchQueue = DispatchQueue(label: "com.hunterhan.FilenFoto.syncDispatchQueue", qos: .background)

    func localIdentifier(dbExtractedAsset: ExtractedFilenAssetInfo, originalFilename: String) throws -> Int64 {
        return try syncDispatchQueue.sync {
            if let assetId = syncDatabase.localIdentifier(livePhotoId: dbExtractedAsset.livePhotoIdentifier, localIdentifier: extractLocalIdentifier(fileName: originalFilename).localIdentifier) {
                return assetId
            } else if let assetId = PhotoDatabase.shared.unsafeInsertAsset(asset: dbExtractedAsset) {
                syncDatabase.insertLocalIdentifier(livePhotoId: dbExtractedAsset.livePhotoIdentifier, localIdentifier: extractLocalIdentifier(fileName: originalFilename).localIdentifier, assetIdentifier: assetId)
                return assetId
            } else {
                throw PhotoSyncError.unknown("Could not insert asset into database")
            }
        }
    }
}

extension PhotoDatabase {
    
}
