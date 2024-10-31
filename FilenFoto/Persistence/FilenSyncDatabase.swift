//
//  FilenSyncDatabase.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SQLite
import Foundation
import os

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

class FileSyncDatabase {
    private let databaseConnection: Connection?
    private let logger: Logger
    
    init(uuid: String) {
        databaseConnection = try? Connection(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(component: "FilenSyncDatabases", directoryHint: .isDirectory).appending(path: "\(uuid).db", directoryHint: .notDirectory).path)
        logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "FilenSyncDatabase-\(uuid)")
        
        do {
            try createTables()
            
            /// Set status to 0
            let _ = try databaseConnection?.run(statusTable.insert(statusNumber <- 0))
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
    }
    
    /// Set status to 1
    func finishPotentialImport() {
        let _ = try? databaseConnection?.run(statusTable.update(statusNumber <- 1))
    }
    
    func insertFile(filenUUID: String, fileName: String) {
        let _ = try? databaseConnection?.run(filenFileTable.insert(
            filenUUIDColumn <- filenUUID,
            fileNameColumn <- fileName,
            fileImportedColumn <- false
        ))
    }

    func finishImport(filenUUID: String) {
        let _ = try? databaseConnection?.run(filenFileTable.filter(filenUUIDColumn == filenUUID).update(fileImportedColumn <- true))
    }

    func getUnimportedFiles() -> [FilenFile] {
        var files = [FilenFile]()
        for file in try! databaseConnection!.prepare(filenFileTable.filter(fileImportedColumn == false)) {
            files.append(FilenFile(filenUUID: file[filenUUIDColumn], fileName: file[fileNameColumn]))
        }
        return files
    }
}

struct FilenFile {
    let filenUUID: String
    let fileName: String
}
