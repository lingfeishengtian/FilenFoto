//
//  ProgressCheckingPhotoSyncProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/5/24.
//

import Foundation

protocol ProgressCheckingPhotoSyncProtocol {
    func cleanTmpDirectory()
    func getTotalNumberOfPhotos() -> Int
    func startSync(onComplete: @escaping () -> Void, onNewDatabasePhotoAdded: @escaping (DBPhotoAsset) -> Void, progressInfo: SyncProgressInfo)
}

extension ProgressCheckingPhotoSyncProtocol {
    func cleanTmpDirectory() {
        do {
            try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory)
            try FileManager.default.createDirectory(at: FileManager.default.temporaryDirectory, withIntermediateDirectories: true)
        } catch {
            print("Cannot remove tmp")
        }
    }
}
