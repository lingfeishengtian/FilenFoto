//
//  PhotoSyncController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Foundation
import Photos
import os
import CoreData

//let REGISTERED_PROVIDERS = [
//
//]

enum SyncError: Error {
    case askForPermissions
    case runtimeError(LocalizedStringResource)
}

let MAX_CONCURRENT_TASKS = 10

class PhotoSyncController {
    private init() {}

    static let shared = PhotoSyncController()
    private let sharedThread = DispatchQueue(label: "com.hunterhan.filenfoto.photosync", qos: .userInitiated, attributes: .concurrent)
    private let logger = Logger(subsystem: "com.hunterhan.filenfoto", category: "PhotoSyncController")
    private let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    private var taskStream: AsyncStream<PHAsset>? = nil
    
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
        
        taskStream = AsyncStream { continuation in
            photoLibrary.enumerateObjects { asset, index, stop in
                if self.stopped {
                    stop.pointee = true
                    continuation.finish()
                    return
                }
                
            }
        }
//        sharedThread.async {
//            photoLibrary.enumerateObjects(self.enumerationBlock(asset:index:stop:))
//        }
    }
    
    func beginTaskIngestion() {
        
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
