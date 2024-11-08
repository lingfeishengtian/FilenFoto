//
//  FilenSyncDatabase.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SQLite
import Foundation
import os

struct FailedStatus {
    let fileUUID: String
    let fileName: String?
    let statusMessage: String
}

fileprivate typealias Expression = SQLite.Expression
// idColumn
let statusTable = Table("status")
let statusNumber = Expression<Int64>("statusNumber")

let filenFileTable = Table("filenFile")
let filenUUIDColumn = Expression<String>("filenUUID")
let fileNameColumn = Expression<String>("fileName")
let fileImportedColumn = Expression<Bool>("imported")

let insertedFilenames = Table("exifIds")
let contentId = Expression<String?>("contentId") // livePhoto content identifier in exif
let cleanedFileIdentifier = Expression<String>("cleanedFileIdentifier") // filen name without extension and BURSTID
let insertedAssetIdentifier = Expression<Int64>("insertedAssetIdentifier") // asset identifier in Photos

let failedFiles = Table("failedFiles")
let failedFileUUID = Expression<String>("failedFileUUID")
let failedFileName = Expression<String?>("failedFileName")
let failedStatusMessage = Expression<String>("failedStatusMessage")

enum SyncStatusCode: Int64 {
    case error = -1
    case started = 0
    case finishIdentification = 1
    case finished = 2
}

class FileSyncDatabase {
    private let databaseConnection: Connection?
    private let logger: Logger
    let dbFilePath: URL
    
    init(uuid: String) {
        dbFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(component: "FilenSyncDatabases", directoryHint: .isDirectory).appending(path: "\(uuid).db", directoryHint: .notDirectory)
        try? FileManager.default.createDirectory(at: dbFilePath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        databaseConnection = try? Connection(dbFilePath.path)
        logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "FilenSyncDatabase-\(uuid)")
        
        do {
            try createTables()
            
            /// Set status to 0
            // does status already exist?
            if try databaseConnection!.scalar(statusTable.count) == 0 {
                let _ = try databaseConnection?.run(statusTable.insert(statusNumber <- SyncStatusCode.started.rawValue))
            }
        } catch {
            logger.error("Could not create tables \(error)")
        }
    }
    
    func createTables() throws {
        let _ = try databaseConnection?.run(statusTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(statusNumber)
        })

        let _ = try databaseConnection?.run(filenFileTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(filenUUIDColumn, unique: true)
            t.column(fileNameColumn)
            t.column(fileImportedColumn)
        })

        let _ = try databaseConnection?.run(insertedFilenames.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(contentId)
            t.column(cleanedFileIdentifier)
            t.column(insertedAssetIdentifier)
        })
        
        let _ = try databaseConnection?.run(failedFiles.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(failedFileUUID, unique: true)
            t.column(failedFileName)
            t.column(failedStatusMessage)
        })
    }
    
    /// Set status to 1
    func finishPotentialImport() {
        let _ = try? databaseConnection?.run(statusTable.update(statusNumber <- 1))
    }
    
    func failedImportStream() -> RowIterator {
        return try! databaseConnection!.prepareRowIterator(failedFiles)
    }
        
    func localIdentifier(livePhotoId: String?, localIdentifier: String) -> Int64? {
        if let livePhotoId, let row = try? databaseConnection!.pluck(insertedFilenames.filter(contentId == livePhotoId)) {
            return row[insertedAssetIdentifier]
        } else if let row = try? databaseConnection!.pluck(insertedFilenames.filter(cleanedFileIdentifier == localIdentifier)) {
            return row[insertedAssetIdentifier]
        }
        return nil
    }
    
    func insertLocalIdentifier(livePhotoId: String?, localIdentifier: String, assetIdentifier: Int64) {
        let _ = try? databaseConnection?.run(insertedFilenames.insert(
            contentId <- livePhotoId,
            cleanedFileIdentifier <- localIdentifier,
            insertedAssetIdentifier <- assetIdentifier
        ))
    }
    
    func insertFile(filenUUID: String, fileName: String) {
        // Does filenUUID already exist?
        if try! databaseConnection!.scalar(filenFileTable.filter(filenUUIDColumn == filenUUID).count) > 0 {
            return
        }
        
        let _ = try? databaseConnection?.run(filenFileTable.insert(
            filenUUIDColumn <- filenUUID,
            fileNameColumn <- fileName,
            fileImportedColumn <- false
        ))
    }

    func finishImport(filenUUID: String) {
        let _ = try? databaseConnection?.run(filenFileTable.filter(filenUUIDColumn == filenUUID).update(fileImportedColumn <- true))
    }
    
    func getStatus() -> SyncStatusCode {
        let statusCode = (try? databaseConnection!.scalar(statusTable.select(statusNumber))) ?? -1
        return SyncStatusCode(rawValue: statusCode) ?? .started
    }

    func getUnimportedFiles() -> FileQueueStreamer {
        return FileQueueStreamer(streamer: try! databaseConnection!.prepareRowIterator(filenFileTable.filter(fileImportedColumn == false)))
    }
    
    func getUnimportedFileCount() -> Int {
        return try! databaseConnection!.scalar(filenFileTable.filter(fileImportedColumn == false).count)
    }
    
    func getTotalFileCount() -> Int {
        return try! databaseConnection!.scalar(filenFileTable.count)
    }
    
    func insertFailedStatus(failStatus: FailedStatus) {
        let _ = try? databaseConnection?.run(failedFiles.insert(
            failedFileUUID <- failStatus.fileUUID,
            failedFileName <- failStatus.fileName,
            failedStatusMessage <- failStatus.statusMessage
        ))
    }
    
    struct FileQueueStreamer {
        let streamer: RowIterator
        
        func next() -> FilenFile? {
            if let row = streamer.next() {
                return FilenFile(filenUUID: row[filenUUIDColumn], fileName: row[fileNameColumn])
            }
            
            return nil
        }
    }
}

struct FilenFile {
    let filenUUID: String
    let fileName: String
}
