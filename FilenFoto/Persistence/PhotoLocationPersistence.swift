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
    @Published var currentStep: String = ""
    @Published var totalAmountOfImages: Int
    var amountOfImagesSynced: Int = 0
    
    init(totalAmountOfImages: Int) {
        self.totalAmountOfImages = totalAmountOfImages
    }
    
    func updateProgress(amountOfImagesSynced: Int, step: String) {
        self.amountOfImagesSynced = amountOfImagesSynced
        let progress = Double(amountOfImagesSynced) / Double(totalAmountOfImages)
        DispatchQueue.main.async {
            if self.totalAmountOfImages == 0 {
                self.progress = 0
            } else {
                self.progress = progress
            }
            self.currentStep = step
        }
    }
    
    func setAmountOfImages(_ amount: Int) {
        DispatchQueue.main.async {
            self.totalAmountOfImages = amount
            let progress = Double(self.amountOfImagesSynced) / Double(self.totalAmountOfImages)
            if self.totalAmountOfImages == 0 {
                self.progress = 0
            } else {
                self.progress = progress
            }
        }
    }
}

class PhotoVisionDatabaseManager {
    static let shared = PhotoVisionDatabaseManager()
    private var cancelOperation: Bool = false
    
    private init() {}
    
    public func cancelSync() {
        cancelOperation = true
    }
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "PhotoVisionDatabaseManager")
    
    public func startSync() -> SyncProgressInfo {
        let progressInfo = SyncProgressInfo(totalAmountOfImages: 0)

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
            
            var count = 0
            var completed = 0
            
            progressInfo.setAmountOfImages(allPhotos.count)
            
            allPhotos.enumerateObjects({ (asset, index, stop) in
                if self.cancelOperation {
                    stop.initialize(to: ObjCBool(true))
                    self.cancelOperation = false
                } else {
                    if count <= 10 {
                        count += 1
                        Task {
                            try await self.fetchAndSyncAssetsFor(asset) { prog, status in
                                if prog >= 1.0 {
                                    completed += 1
                                }
                                
                                progressInfo.updateProgress(amountOfImagesSynced: completed, step: status)
                            }
                        }
                    }
                }
            })
        }
        
        return progressInfo
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
        
        var assetResources = PHAssetResource.assetResources(for: asset)
        var resourceTmpLoc: URL? = nil
        var resourceType: PHAssetResourceType? = nil
        let resources = await withTaskGroup(of: (PHAssetResource, String)?.self) { group in
            var collected = [(PHAssetResource, String)]()
            var thumbnailCandidates = [(URL, PHAssetResourceType)]()
            
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
                    
                    defer {
                        thumbnailCandidates.append((tmpLocation, assetResource.type))
                    }
                    
                    do {
                        try await PHAssetResourceManager.default().writeData(for: assetResource, toFile: tmpLocation, options: options)
                        let itemJSON = try await filenClient.uploadFile(url: tmpLocation.path, parent: filenPhotoFolderUUID!)
                        return (assetResource, itemJSON.uuid)
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
            
            thumbnailCandidates = thumbnailCandidates.sorted(by: { a, b in
                let isFilePhoto = self.photoResourceTypes.firstIndex(of: a.1)
                let isCurrentPhoto = self.photoResourceTypes.firstIndex(of: b.1)
                let isFileVideo = self.videoResourceTypes.firstIndex(of: a.1)
                let isCurrentVideo = self.videoResourceTypes.firstIndex(of: b.1)
                
                if isFileVideo != nil && isCurrentVideo != nil {
                    return isFileVideo! < isCurrentVideo!
                } else {
                    return isFilePhoto ?? Int.max < isCurrentPhoto ?? Int.max
                }
            })
            
            resourceTmpLoc = thumbnailCandidates.first?.0
            resourceType = thumbnailCandidates.first?.1
            
            return collected
        }
        
        return PhotoAssetFilenResults(assetsToCloud: resources, photoOrVideoClassification: resourceTmpLoc, mediaTypeOfClassificationFile: resourceType)
    }
    
    private func classifyAndTextRecognize(image imageURL: URL) async -> ([VNClassificationObservation], [VNRecognizedTextObservation]) {
        let image = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        let cgImage = CGImageSourceCreateImageAtIndex(image!, 0, nil)
        
        print("Vision request for \(imageURL)")
        
        return await classifyAndTextRecognize(image: cgImage!)
    }
    
    private func classifyAndTextRecognize(image cgImage: CGImage) async -> ([VNClassificationObservation], [VNRecognizedTextObservation]) {
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var imageClassifications: [VNClassificationObservation] = []
        var recognizedTextClassifications: [VNRecognizedTextObservation] = []
        
        let imageRequest: VNClassifyImageRequest = {
            let req = VNClassifyImageRequest(completionHandler: { (retReq, err) in
                for res in retReq.results! {
                    if !res.confidence.isZero && !res.confidence.isNaN && res.confidence >= 0.1, let imgClassObserver = res as? VNClassificationObservation {
                        imageClassifications.append(imgClassObserver)
                    } else {
                        break
                    }
                }
            })

            return req
        }()
        
        let textRequest: VNRecognizeTextRequest = {
            let req = VNRecognizeTextRequest(completionHandler: { (retReq, err) in
                for res in retReq.results! {
                    if !res.confidence.isZero && !res.confidence.isNaN && res.confidence >= 0.1, let recogText = res as? VNRecognizedTextObservation {
                        recognizedTextClassifications.append(recogText)
                    } else {
                        break
                    }
                }
            })
            return req
        }()
        
        
#if targetEnvironment(simulator)
        imageRequest.usesCPUOnly = true
        textRequest.usesCPUOnly = true
#endif
        
        do {
            try imageRequestHandler.perform([imageRequest, textRequest])
        } catch {
            self.logger.warning("Vision request failed for image with error: \(error)")
        }
        return (imageClassifications, recognizedTextClassifications)
    }
    
    private func classifyAndTextRecognize(video videoURL: URL) async -> ([VNClassificationObservation], [VNRecognizedTextObservation]) {
        let asset = AVAsset(url: videoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        
        print("Classifying Video")
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            return await classifyAndTextRecognize(image: img)
        } catch {
            print(error.localizedDescription)
            return ([], [])
        }
    }
    
    let thumbnailsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("thumbnails", conformingTo: .folder)

    private func fetchAndSyncAssetsFor(_ asset: PHAsset, updateProgressOfCurrentFile: @escaping (Double, String) -> Void) async throws {
        if PhotoDatabase.shared.doesPhotoExist(asset) {
            logger.info("\(asset.localIdentifier) already exists in database. Skipping...")
            updateProgressOfCurrentFile(1.0, "Image already exists, skipping...")
            return
        }
        
        print("Found asset \(asset.mediaSubtypes) with id \(asset.localIdentifier) created \(asset.creationDate ?? Date.now)")
        let retrieveAndUploadedAssets = (try await retrieveAssetResources(asset))
        updateProgressOfCurrentFile(0.5, "Uploaded image to Filen...")
        var recognizedClassifyObject = ([VNClassificationObservation](), [VNRecognizedTextObservation]())
        var compressedThumbnailUrl: URL?
        
        if let targetClassfyFileURL = retrieveAndUploadedAssets.photoOrVideoClassification, let mediaTypeOfClassificationFile = retrieveAndUploadedAssets.mediaTypeOfClassificationFile, FileManager.default.fileExists(atPath: targetClassfyFileURL.path) {
            switch mediaTypeOfClassificationFile {
            case .photo, .adjustmentBasePhoto, .alternatePhoto, .fullSizePhoto:
                recognizedClassifyObject = await classifyAndTextRecognize(image: targetClassfyFileURL)
                break
            case .video, .adjustmentBaseVideo, .fullSizeVideo, .pairedVideo:
                recognizedClassifyObject = await classifyAndTextRecognize(video: targetClassfyFileURL)
                break
            default:
                break
            }
            
            do {
                if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
                    try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
                }
                compressedThumbnailUrl = thumbnailsDirectory.appendingPathComponent(targetClassfyFileURL.lastPathComponent, conformingTo: .jpeg)
                try await ImageCompressor.compressImage(from: targetClassfyFileURL, outputDestination: compressedThumbnailUrl!, compressionQuality: 0.0)
                try FileManager.default.removeItem(at: targetClassfyFileURL)
            } catch {
                if FileManager.default.fileExists(atPath: targetClassfyFileURL.path) {
                    compressedThumbnailUrl = thumbnailsDirectory.appendingPathComponent(targetClassfyFileURL.lastPathComponent, conformingTo: .jpeg)
                    try FileManager.default.copyItem(at: targetClassfyFileURL, to: compressedThumbnailUrl!)
                }
                logger.warning("Unable to create thumbnail remove classification file at \(targetClassfyFileURL.path)")
            }
        }
        
        updateProgressOfCurrentFile(0.75, "Identified image contents...")
        
        switch PhotoDatabase.shared.insertPhoto(asset: asset, resources: retrieveAndUploadedAssets.assetsToCloud, imageClassificationResults: recognizedClassifyObject.0, textResultClassificationResults: recognizedClassifyObject.1, thumbnailLocation: compressedThumbnailUrl ?? FileManager.default.temporaryDirectory) {
        case .exists:
            logger.error("Photo already exists in database")
            updateProgressOfCurrentFile(1.0, "Photo already exists on the cloud")
        case .failed:
            logger.error("Failed to insert into database")
            updateProgressOfCurrentFile(1.0, "Failure! This isn't supposed to happen")
        case .success:
            logger.info("Inserted photo into database")
            updateProgressOfCurrentFile(1.0, "Finished inserting into database")
        }
    }
}

struct PhotoAssetFilenResults {
    let assetsToCloud: [(PHAssetResource, String)]
    let photoOrVideoClassification: URL?
    let mediaTypeOfClassificationFile: PHAssetResourceType?
}

extension PHAssetMediaSubtype: @retroactive CustomStringConvertible {
    public var description: String {
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
        
        let options = debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let result = options.joined(separator: ", ")
        return "PHAssetMediaSubtype([\(result)])"
    }
}