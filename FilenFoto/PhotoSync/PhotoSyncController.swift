//
//  PhotoSyncController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import CoreData
import Foundation
import Photos
import os

let REGISTERED_PROVIDERS = [
    "ThumbnailProvider": ThumbnailProvider.shared
]

enum SyncError: Error {
    case askForPermissions
    case runtimeError(LocalizedStringResource)
}

let MAX_CONCURRENT_TASKS = 3
typealias ProviderAction = () async -> Bool

class PhotoSyncController {
    private init() {}

    static let shared = PhotoSyncController()
    private let logger = Logger(subsystem: "com.hunterhan.filenfoto", category: "PhotoSyncController")

    private var taskStream: AsyncStream<(PHAsset, UUID, PhotoActionProviderDelegate)>? = nil

    var stopped = false

    func beginSync() throws {
        if !(try checkPermissionStatus()) {
            throw SyncError.askForPermissions
        }

        if stopped {
            return
        }

        let photoLibrary = PHAsset.fetchAssets(with: PHFetchOptions())
        logger.info("Starting sync of \(photoLibrary.count) photos")

        Task.detached(priority: .background) {
            await withTaskGroup(of: Bool.self) { group in
                var initialTasks = 0

                func addToWorker(task: @escaping ProviderAction) async {
                    if initialTasks < MAX_CONCURRENT_TASKS {
                        initialTasks += 1
                        group.addTask {
                            await task()
                        }
                    } else {
                        if let finishedTask = await group.next() {
                            group.addTask {
                                await task()
                            }
                        }
                    }
                }

                await self.batchedTaskGroup(addToWorker: addToWorker, photoLibrary: photoLibrary)
                
                try? FFCoreDataManager.shared.managedObjectContext.save()
            }
        }
    }

    func batchedTaskGroup(addToWorker: (@escaping ProviderAction) async -> Void, photoLibrary: PHFetchResult<PHAsset>) async {
        for index in 0..<photoLibrary.count {
            let asset = photoLibrary.object(at: index)
            print("Enumerating asset \(index + 1) of \(photoLibrary.count)")

            if self.stopped {
                return
            }

            let filenAsset = FotoAsset(context: FFCoreDataManager.shared.managedObjectContext)
            set(filenFoto: filenAsset, for: asset)
            
            FFCoreDataManager.shared.managedObjectContext.insert(filenAsset)
            
            let uuid = UUID()
            for provider in REGISTERED_PROVIDERS.values {
                await addToWorker {
                    let result = await provider.initiateProtocol(for: asset, with: uuid)
                    return result
                }
            }
        }
    }
    
    func set(filenFoto: FotoAsset, for asset: PHAsset) {
        filenFoto.uuid = UUID()
//        filenFoto.cloudUuid = asset. TODO: Figure out
        filenFoto.localUuid = asset.localIdentifier
        filenFoto.dateCreated = asset.creationDate
        filenFoto.dateModified = asset.modificationDate
        filenFoto.mediaType = Int16(asset.mediaType.rawValue)
        filenFoto.mediaSubtypes = Int64(asset.mediaSubtypes.rawValue)
    }
}

extension PhotoSyncController {
    func checkPermissionStatus(status: PHAuthorizationStatus? = nil) throws -> Bool {
        let photosAuthorizationStatus = status ?? PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch photosAuthorizationStatus {
        case .notDetermined:
            return false
        case .restricted:
            throw SyncError.runtimeError("App entitlements are incorrect.")
        case .denied:
            throw SyncError.runtimeError("Permission to access photos was denied.")
        case .authorized, .limited:
            return true
        @unknown default:
            return false
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            completion((try? self.checkPermissionStatus(status: status)) ?? false)
        }
    }
}
