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

let MAX_CONCURRENT_TASKS = 3

class PhotoSyncController {
    private init() {}

    static let shared = PhotoSyncController()
    let logger = Logger(subsystem: "com.hunterhan.filenfoto", category: "PhotoSyncController")

    var stopped = false

    func beginSync() throws {
        if !(try checkPermissionStatus()) {
            throw FilenFotoError.noCameraPermissions
        }

        if stopped {
            return
        }

        let photoLibrary = PHAsset.fetchAssets(with: PHFetchOptions())
        logger.info("Starting sync of \(photoLibrary.count) photos")

        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                var initialTasks = 0

                func addToWorker(task: @escaping () async -> Void) async {
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

                for fotoAssetIndex in 0..<photoLibrary.count {
                    let asset = photoLibrary.object(at: fotoAssetIndex)

                    if self.stopped {
                        break
                    }

                    await addToWorker {
                        await self.startProviderActions(for: asset)
                    }
                }
            }

            await FFCoreDataManager.shared.saveContextIfNeeded()
        }
    }

    func startProviderActions(for asset: PHAsset) async {
        let fotoAsset = await FFCoreDataManager.shared.insert(for: asset)
        let workingAsset = WorkingSetFotoAsset(asset: fotoAsset)

        do {
            try await workingAsset.retrieveResources(withSupportingPHAsset: asset)
        } catch {
            logger.error("\(error)")
            PhotoContext.shared.report("An error ocurred while pulling resources for \(asset.localIdentifier)")
            return
        }

        let context = FFCoreDataManager.shared.newChildContext()

        await runProviders(for: workingAsset)
    }
}

extension PhotoSyncController {
    func checkPermissionStatus(status: PHAuthorizationStatus? = nil) throws -> Bool {
        let photosAuthorizationStatus = status ?? PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch photosAuthorizationStatus {
        case .notDetermined:
            return false
        case .restricted:
            throw FilenFotoError.appBundleBroken
        case .denied:
            throw FilenFotoError.cameraPermissionDenied
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
