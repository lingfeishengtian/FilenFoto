//
//  PhotoSyncController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Combine
import CoreData
import Foundation
import Photos
import os

let MAX_CONCURRENT_TASKS = 3

class PhotoSyncController: ObservableObject {
    var progress = Progress()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        progress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

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

        progress.totalUnitCount = calculateTotalProgressUnits(for: photoLibrary.count)

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
        
        #if DEBUG
        FFWorkingSet.default.assertWorkingSetIsEmpty()
        #endif
    }

    func startProviderActions(for asset: PHAsset) async {
        let fotoAsset = FFCoreDataManager.shared.insert(for: asset)
        let workingAsset = FFWorkingSet.default.requestWorkingSet(for: fotoAsset)

        do {
            try await workingAsset.retrieveResources(withSupportingPHAsset: asset)
        } catch {
            logger.error("\(error)")
            PhotoContext.shared.report("An error ocurred while pulling resources for \(asset.localIdentifier)")
            assert(false)
            return
        }

        // TODO: Make working set asset actually report progress
        completeWorkingSetAssetRetrieval()

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
