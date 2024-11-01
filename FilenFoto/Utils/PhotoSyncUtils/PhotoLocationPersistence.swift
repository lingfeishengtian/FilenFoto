//
//  PhotoLocationPersistence.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/15/24.
//

import Foundation
import Photos
import os
import Vision
import FilenSDK
import CryptoKit

//fileprivate let sha256Queue = DispatchQueue(label: "com.filenfoto.sha256Queue")

func getSHA256(forFile url: URL) throws -> String {
    //    return try sha256Queue.sync {
    
    let handle = try FileHandle(forReadingFrom: url)
    var hasher = SHA256()
    while autoreleasepool(invoking: {
        let nextChunk = handle.readData(ofLength: SHA256.blockByteCount)
        guard !nextChunk.isEmpty else { return false }
        hasher.update(data: nextChunk)
        return true
    }) { }
    let digest = hasher.finalize()
    //    return digest
    
    // Here's how to convert to string form
    return digest.map { String(format: "%02hhx", $0) }.joined()
    //    }
}

var filenPhotoFolderUUID: String? {
    get {
        return UserDefaults.standard.string(forKey: "filenPhotoFolderUUID")
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "filenPhotoFolderUUID")
    }
}

public enum PhotoSyncError {
    case permissionDenied
    case restrictedAccess
    case filenClientError(String)
    
    case unknown(String)
}

extension PhotoSyncError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Acess to photo library was denied"
        case .restrictedAccess:
            return "You are not permitted by the system to access the photo library"
        case .filenClientError(let error):
            return "Filen client error \(error)"
        case .unknown(let category):
            return "An unknown \(category) error has occured"
        }
    }
}

class SyncProgressInfo : ObservableObject {
    @Published var progress: Double = 0
    private var imageSyncProgressQueue: [String:ImageSyncProgress] = [:]
    private var lastChanged = [ImageSyncProgress]()
    // variable here for speed purposes
    private var completedImages = 0
    let maxStatusMessages: Int = 10
    private var onComplete: () -> Void
    private var overrideMaxImages: Int = 0
    
    init() {
        self.onComplete = { }
    }
    
    public func setOnComplete(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    struct ImageSyncProgress {
        public var internalProgress: Double = 0.0
        public var internalMessage: String
        public var phAssetLocalIdentifier: String
        public var isImage: Bool
    }
    
    private func checkLastChanged() {
        while lastChanged.count > maxStatusMessages {
            lastChanged.removeLast()
        }
    }
    
    public func reset() {
        DispatchQueue.main.async {
            self.progress = 0
            self.completedImages = 0
            self.imageSyncProgressQueue.removeAll()
        }
    }
    
    public func setMaxImages(maxImages: Int) {
        DispatchQueue.main.async {
            self.overrideMaxImages = maxImages
        }
    }
    
    private func updateProgress() {
        progress = 0
        completedImages = 0
        for (_, value) in imageSyncProgressQueue {
            if value.internalProgress >= 1.0 {
                completedImages += 1
            }
            progress += value.internalProgress / Double(max(imageSyncProgressQueue.count, overrideMaxImages))
        }
        print("Current progress: \(progress) with \(imageSyncProgressQueue.count) images")
    }
    
    func addImage(phAsset: PHAsset) {
        DispatchQueue.main.async {
            self.imageSyncProgressQueue[phAsset.localIdentifier] = ImageSyncProgress(internalMessage: "Syncing \(phAsset.localIdentifier)...", phAssetLocalIdentifier: phAsset.localIdentifier, isImage: phAsset.mediaType == .image)
            self.lastChanged.insert(self.imageSyncProgressQueue[phAsset.localIdentifier]!, at: 0)
            
            self.checkLastChanged()
            self.updateProgress()
        }
    }
    
    func updateImageProgress(progress localProgress: Double, message: String, phAsset: PHAsset) {
        DispatchQueue.main.async {
            if let imageInQueue = self.imageSyncProgressQueue[phAsset.localIdentifier] {
                if localProgress >= 1.0 && imageInQueue.internalProgress < 1.0 {
                    self.completedImages += 1
                    if message != "Image already exists, skipping..." {
                        self.onComplete()
                    }
                }
                self.imageSyncProgressQueue[phAsset.localIdentifier]?.internalProgress = localProgress
                self.imageSyncProgressQueue[phAsset.localIdentifier]?.internalMessage = message
                self.lastChanged.removeAll(where: { $0.phAssetLocalIdentifier == phAsset.localIdentifier })
                self.lastChanged.insert(self.imageSyncProgressQueue[phAsset.localIdentifier]!, at: 0)
                
                self.checkLastChanged()
                self.updateProgress()
            }
        }
    }
    
    func getTotalProgress() -> (completedImages: Int, totalImages: Int) {
        return (completedImages: completedImages, max(imageSyncProgressQueue.count, overrideMaxImages))
    }
    
    func getLastChanged() -> [ImageSyncProgress] {
        return lastChanged
    }
}

class PhotoVisionDatabaseManager {
    static let shared = PhotoVisionDatabaseManager()
    static let maxConcurrentTasks: Int = 4
    private var cancelOperation: Bool = false
    
    private init() {}
    
    public func cancelSync() {
        cancelOperation = true
    }
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "PhotoVisionDatabaseManager")
    
    func cleanTmpDirectory() {
        do {
            try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory)
            try FileManager.default.createDirectory(at: FileManager.default.temporaryDirectory, withIntermediateDirectories: true)
        } catch {
            print("Cannot remove tmp")
        }
    }
    
    public func getTotalNumberOfPhotos() -> Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        fetchOptions.includeAllBurstAssets = true
        let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        return allPhotos.count
    }
    
    public func startSync(onComplete: @escaping () -> Void = {}, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void, existingSync: SyncProgressInfo? = nil) -> SyncProgressInfo {
        cleanTmpDirectory()
        let progressInfo = existingSync ?? SyncProgressInfo()
        progressInfo.reset()
        
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            switch status {
            case .authorized, .limited:
                print("Permissions correct, starting sync")
                break
            case .denied:
                throw PhotoSyncError.permissionDenied
            case .restricted:
                throw PhotoSyncError.restrictedAccess
            case .notDetermined:
                throw PhotoSyncError.unknown("permission")
            @unknown default:
                throw PhotoSyncError.unknown("unknown category")
            }
            
            guard let filenClient = getFilenClientWithUserDefaultConfig() else {
                throw PhotoSyncError.filenClientError("Invalid default config")
            }
            let returnedFiles = try await filenClient.dirContent(uuid: filenPhotoFolderUUID!)
            currentFileNames = []
            for file in returnedFiles.uploads {
                let dirFiles = try filenClient.decryptFileName(metadata: file.metadata)
                currentFileNames.append(dirFiles)
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = true
            fetchOptions.includeAllBurstAssets = true
            let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
            progressInfo.setMaxImages(maxImages: allPhotos.count)
            
            var index = 0
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< PhotoVisionDatabaseManager.maxConcurrentTasks {
                    if index >= allPhotos.count {
                        break
                    }
                    let curInd = index
                    index += 1
                    group.addTask {
                        await self.initiateAssetUploadAndVisionTasks(allPhotos.object(at: curInd), progressInfo: progressInfo, onNewDatabasePhotoAdded: onNewDatabasePhotoAdded)
                    }
                }
                while let _ = await group.next() {
                    if index >= allPhotos.count {
                        break
                    }
                    if !self.cancelOperation {
                        let curInd = index
                        index += 1
                        
                        group.addTask {
                            await self.initiateAssetUploadAndVisionTasks(allPhotos.object(at: curInd), progressInfo: progressInfo, onNewDatabasePhotoAdded: onNewDatabasePhotoAdded)
                        }
                    } else {
                        self.cancelOperation = false
                    }
                }
            }
        }
        
        return progressInfo
    }
    
    private func initiateAssetUploadAndVisionTasks(_ asset: PHAsset, progressInfo: SyncProgressInfo, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void) async {
        do {
            progressInfo.addImage(phAsset: asset)
            try await self.fetchAndSyncAssetsFor(asset) { prog, status in
                progressInfo.updateImageProgress(progress: prog, message: status, phAsset: asset)
            } onNewDBPhotoInserted: { dbPhoto in
                onNewDatabasePhotoAdded(dbPhoto)
            }
        } catch {
            self.logger.error("Failure while fetching and syncing asset: \(error.localizedDescription)")
        }
    }
    
    var currentFileNames: [String] = []
    let photoResourceTypes: [PHAssetResourceType] = [.photo, .adjustmentBasePhoto, .alternatePhoto, .fullSizePhoto]
    let videoResourceTypes: [PHAssetResourceType] = [.video, .adjustmentBaseVideo, .adjustmentBasePairedVideo, .fullSizeVideo]
        
    private func retrieveAssetResources(_ asset: PHAsset) async throws -> PhotoAssetFilenResults {
        guard let filenClient = getFilenClientWithUserDefaultConfig() else {
            throw PhotoSyncError.filenClientError("Invalid default config")
        }
        
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress in
            // TODO: Implement
            self.logger.info("Progress: \(progress) for asset \(asset.localIdentifier)")
        }
        
        let assetResources = PHAssetResource.assetResources(for: asset)
        let resources = await withTaskGroup(of: (FilenEquivelentAsset)?.self) { group in
            var collected = [FilenEquivelentAsset]()
            for assetResource in assetResources {
                group.addTask {
                    var fileName = assetResource.originalFilename
                    while self.currentFileNames.contains(fileName) {
                        fileName = UUID().uuidString + fileName
                    }
                    let tmpLocation = FileManager.default.temporaryDirectory.appending(path: fileName)
                    
                    do {
                        try FileManager.default.removeItem(at: tmpLocation)
                    } catch {
                        print("Could not remove temporary file: \(tmpLocation.path) \(error)")
                    }
                    
                    do {
                        try await PHAssetResourceManager.default().writeData(for: assetResource, toFile: tmpLocation, options: options)
                        let itemJSON = try await filenClient.uploadFile(url: tmpLocation.path, parent: filenPhotoFolderUUID!)
                        return FilenEquivelentAsset(phAssetResource: assetResource, filenUuid: itemJSON.uuid, fileHash: try getSHA256(forFile: tmpLocation), tmpLoc: tmpLocation)
                    } catch {
                        self.logger.error("Error occurred when retrieving asset \(assetResource.originalFilename) with error: \(error)")
                    }
                    return nil
                }
            }
            
            for await value in group {
                if value != nil {
                    collected.append(value!)
                }
            }
            
            collected = collected.sorted(by: { first, second in
                let a = first.phAssetResource.type
                let b = second.phAssetResource.type
                let isFilePhoto = self.photoResourceTypes.firstIndex(of: a)
                let isCurrentPhoto = self.photoResourceTypes.firstIndex(of: b)
                let isFileVideo = self.videoResourceTypes.firstIndex(of: a)
                let isCurrentVideo = self.videoResourceTypes.firstIndex(of: b)
                
                if isFileVideo != nil && isCurrentVideo != nil {
                    return isFileVideo! < isCurrentVideo!
                } else {
                    return isFilePhoto ?? Int.max < isCurrentPhoto ?? Int.max
                }
            })
            
            return collected
        }
        
        return PhotoAssetFilenResults(assetsToCloud: resources)
    }
    
    let thumbnailsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("thumbnails", conformingTo: .folder)
    
    // TODO: Clean thumbnails not referenced in the database
    public func cleanThumbnailsDirectory() {
        
    }
    
    private let finishImageClassificationQueue = DispatchQueue(label: "com.hunterhan.FilenFoto.imageClassificationCompletionHandler", qos: .utility)
    
    private func fetchAndSyncAssetsFor(_ asset: PHAsset, updateProgressOfCurrentFile: @escaping (Double, String) -> Void, onNewDBPhotoInserted: @escaping (DBPhotoAsset) -> Void) async throws {
        if PhotoDatabase.shared.doesPhotoExist(asset) {
            logger.info("\(asset.localIdentifier) already exists in database. Skipping...")
            updateProgressOfCurrentFile(1.0, "Image already exists, skipping...")
            return
        }
        
        print("Found asset \(asset.mediaSubtypes) with id \(asset.localIdentifier) created \(asset.creationDate ?? Date.now)")
        let retrieveAndUploadedAssets = (try await retrieveAssetResources(asset))
        
        updateProgressOfCurrentFile(0.5, "Uploaded image to Filen...")
        var compressedThumbnailUrl: URL?
        
        let passthroughStruct = FinalRecognitionPassthroughResults(
            asset: asset,
            retrieveAndUploadedAssets: retrieveAndUploadedAssets,
            updateProgressOfCurrentFile: updateProgressOfCurrentFile,
            onNewDBPhotoInserted: onNewDBPhotoInserted
        )
        
        if let targetClassfyFileURL = retrieveAndUploadedAssets.assetsToCloud.first?.tmpLoc, let mediaTypeOfClassificationFile = retrieveAndUploadedAssets.assetsToCloud.first?.phAssetResource.type, FileManager.default.fileExists(atPath: targetClassfyFileURL.path) {
            do {
                if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
                    try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
                }
                compressedThumbnailUrl = thumbnailsDirectory.appendingPathComponent(targetClassfyFileURL.lastPathComponent, conformingTo: .jpeg)
                switch mediaTypeOfClassificationFile {
                case .photo, .adjustmentBasePhoto, .alternatePhoto, .fullSizePhoto:
                    ImageVision.classifyAndTextRecognize(image: targetClassfyFileURL) { results, err in
                        if let recognizedClassifyObject = results {
                            Task(priority: .high) { [recognizedClassifyObject] in
                                try await ImageCompressor.compressImage(from: targetClassfyFileURL, outputDestination: compressedThumbnailUrl!)
                                try FileManager.default.removeItem(at: targetClassfyFileURL)
                                self.insertFinalDataIntoDatabase(passthroughStruct, classificationResults: recognizedClassifyObject, compressedThumbnailUrl: compressedThumbnailUrl)
                                
                                self.deleteResources(retrieveAndUploadedAssets: retrieveAndUploadedAssets)
                            }
                        } else {
                            self.logger.error("Failed to classify with error \(err)")
                            self.insertFinalDataIntoDatabase(passthroughStruct, classificationResults: ([], []), compressedThumbnailUrl: compressedThumbnailUrl)
                            self.deleteResources(retrieveAndUploadedAssets: retrieveAndUploadedAssets)
                        }
                    }
                    break
                case .video, .adjustmentBaseVideo, .fullSizeVideo, .pairedVideo:
//                    if let vidRecogRes =
                    ImageVision.classifyAndTextRecognize(video: targetClassfyFileURL) { results, err in
                        if let vidRecogRes = results {
                            Task(priority: .high) { [vidRecogRes] in
                                try await ImageCompressor.compressImage(from: vidRecogRes.generatedCGImage, outputDestination: compressedThumbnailUrl!)
                                try FileManager.default.removeItem(at: targetClassfyFileURL)
                                
                                self.insertFinalDataIntoDatabase(passthroughStruct, classificationResults: vidRecogRes.photoRecog, compressedThumbnailUrl: compressedThumbnailUrl)
                                self.deleteResources(retrieveAndUploadedAssets: retrieveAndUploadedAssets)
                            }
                        } else {
                            // TODO: Warn user that cannot insert video
                            self.logger.error("Failed to classify with error \(err)")
                            self.deleteResources(retrieveAndUploadedAssets: retrieveAndUploadedAssets)
                        }
                    }
                    break
                default:
                    break
                }
                
            } catch {
                if FileManager.default.fileExists(atPath: targetClassfyFileURL.path) {
                    compressedThumbnailUrl = thumbnailsDirectory.appendingPathComponent(targetClassfyFileURL.lastPathComponent, conformingTo: .jpeg)
                    try FileManager.default.copyItem(at: targetClassfyFileURL, to: compressedThumbnailUrl!)
                }
                logger.warning("Unable to create thumbnail remove classification file at \(targetClassfyFileURL.path)")
            }
        }
    }
    
    private func deleteResources(retrieveAndUploadedAssets: PhotoAssetFilenResults) {
        for resource in retrieveAndUploadedAssets.assetsToCloud {
            do {
                try FileManager.default.removeItem(at: resource.tmpLoc)
            } catch {
                logger.info("Couldn't remove \(error)")
            }
        }
    }
    
    private func insertFinalDataIntoDatabase(_ passthrough: FinalRecognitionPassthroughResults, classificationResults: ([VNClassificationObservation], [VNRecognizedTextObservation]), compressedThumbnailUrl: URL?) {
        passthrough.updateProgressOfCurrentFile(0.75, "Identified image contents...")
        
        switch PhotoDatabase.shared.insertPhoto(asset: passthrough.asset, resources: passthrough.retrieveAndUploadedAssets.assetsToCloud, imageClassificationResults: classificationResults.0, textResultClassificationResults: classificationResults.1, thumbnailLocation: compressedThumbnailUrl ?? FileManager.default.temporaryDirectory) {
        case .exists:
            logger.error("Photo already exists in database")
            passthrough.updateProgressOfCurrentFile(1.0, "Photo already exists on the cloud")
        case .failed:
            logger.error("Failed to insert into database")
            passthrough.updateProgressOfCurrentFile(1.0, "Failure! This isn't supposed to happen")
        case .success(let dbPhoto):
            logger.info("Inserted photo into database")
            passthrough.updateProgressOfCurrentFile(1.0, "Finished inserting into database")
            passthrough.onNewDBPhotoInserted(dbPhoto)
        }
    }
    
    private struct FinalRecognitionPassthroughResults {
        let asset: PHAsset
        let retrieveAndUploadedAssets: PhotoAssetFilenResults
        let updateProgressOfCurrentFile: (Double, String) -> Void
        let onNewDBPhotoInserted: (DBPhotoAsset) -> Void
    }
}

struct FilenEquivelentAsset {
    let phAssetResource: PHAssetResource
    let filenUuid: String
    let fileHash: String
    let tmpLoc: URL
}

struct PhotoAssetFilenResults {
    // Sorted where first is thumbnail
    let assetsToCloud: [FilenEquivelentAsset]
    //    let photoOrVideoClassification: URL?
    //    let mediaTypeOfClassificationFile: PHAssetResourceType?
}

extension PHAssetMediaSubtype: @retroactive CustomStringConvertible {
    public var description: String {
        let options = self.includedTypes.map({ $0.1 })
        let result = options.joined(separator: ", ")
        return "PHAssetMediaSubtype([\(result)])"
    }
    
    public var includedTypes: [(Self, String)] {
        var debugDescriptions: [(Self, String)] = [
            // Photo subtypes
            (.photoPanorama, ".photoPanorama"),
            (.photoHDR, ".photoHDR"),
            (.photoScreenshot, ".photoScreenshot"),
            (.photoLive, ".photoLive"),
            (.photoDepthEffect, ".photoDepthEffect"),
            // Video subtypes
            (.videoStreamed, ".videoStreamed"),
            (.videoHighFrameRate, ".videoHighFrameRate"),
            (.videoTimelapse, ".videoTimelapse")
        ]
        
        if #available(iOS 15, *) {
            debugDescriptions.append((.videoCinematic, ".videoCinematic"))
        }
        
        if #available(iOS 16, *) {
            debugDescriptions.append((.spatialMedia, ".spatialMedia"))
        }
        
        return debugDescriptions.filter { contains($0.0) }
    }
}