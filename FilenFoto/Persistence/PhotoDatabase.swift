//
//  PhotoDatabase.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/16/24.
//

import Foundation
import Photos
import SQLite
import os
import Vision

class PhotoDatabase {
    static let shared = PhotoDatabase()
    private static let databaseName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotoDatabase.db", conformingTo: .database)
    private let databaseConnection: Connection?
    
    private init() {
        self.databaseConnection = try? Connection(PhotoDatabase.databaseName.path)
    }
    
    // Bug in SQLite right now
    typealias Expression = SQLite.Expression
    let photoAssetTable = Table("photoAsset")
    let idColumn = Expression<Int64>("id")
    let assetColumn = Expression<String>("localIdentifier")
    let mediaSubtypeColumn = Expression<Int64>("mediaSubtype")
    let creationDateColumn = Expression<Date>("creationDate")
    let modificationDateColumn = Expression<Date>("modificationDate")
    let locationLongitudeColumn = Expression<Double>("locationLongitude")
    let locationLatitudeColumn = Expression<Double>("locationLatitude")
    let hashColumn = Expression<String?>("hash")
    let completedAnalysis = Expression<Bool>("completedAnalysis")
    let favorited = Expression<Bool>("favorited")
    let hidden = Expression<Bool>("hidden")
    let thumbnailName = Expression<String>("thumbnailLocation")
    
    let photoResourcesTable = Table("photoResources")
    let uuidColumn = Expression<String>("uuid")
    let resourceType = Expression<Int64>("resourceType")
    
    // id
    let identifiedObjectsTable = Table("identifiedObjects")
    let assetIdColumn = Expression<Int64?>("assetId")
    let objectNameColumn = Expression<String>("objectName")
    let confidenceColumn = Expression<Double>("confidence")
    
    // id
    // assetIdColumn
    let recognizedTextTable = Table("recognizedText")
    let textColumn = Expression<String>("text")
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "PhotoDatabase")
    
    func createPhotoAssetTable() {
        let _ = try? databaseConnection?.run(photoAssetTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetColumn)
            t.column(mediaSubtypeColumn)
            t.column(creationDateColumn)
            t.column(modificationDateColumn)
            t.column(locationLongitudeColumn)
            t.column(locationLatitudeColumn)
            t.column(hashColumn)
            t.column(favorited)
            t.column(hidden)
            t.column(thumbnailName)
            t.column(completedAnalysis, defaultValue: false)
        })
        
        let _ = try? databaseConnection?.run(photoResourcesTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetIdColumn)
            t.column(resourceType)
            t.column(uuidColumn)
            t.foreignKey(assetIdColumn, references: photoAssetTable, idColumn)
        })
        
        let _ = try? databaseConnection?.run(identifiedObjectsTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetIdColumn)
            t.column(objectNameColumn)
            t.column(confidenceColumn)
            t.foreignKey(assetIdColumn, references: photoAssetTable, idColumn)
        })
        
        let _ = try? databaseConnection?.run(recognizedTextTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetIdColumn)
            t.column(textColumn)
            t.column(confidenceColumn)
            t.foreignKey(assetIdColumn, references: photoAssetTable, idColumn)
        })
    }
    
    func doesPhotoExist(_ asset: PHAsset) -> Bool {
        let query = photoAssetTable.filter(assetColumn == asset.localIdentifier)
        let count = try? databaseConnection?.scalar(query.count)
        return count ?? 0 > 0
    }
    
    func insertPhoto(asset: PHAsset, resources: [(PHAssetResource, String)], imageClassificationResults: [VNClassificationObservation], textResultClassificationResults: [VNRecognizedTextObservation], thumbnailLocation: URL) -> InsertPhotoResult {
        print(PhotoDatabase.databaseName)
        
        if doesPhotoExist(asset) {
            return .exists
        }
        
        createPhotoAssetTable()

        let mediaSubtype = asset.mediaSubtypes.rawValue
        let creationDate = asset.creationDate ?? Date.now
        let modificationDate = asset.modificationDate ?? Date.now
        let location = asset.location?.coordinate ?? CLLocationCoordinate2D()
        let hash = asset.hash
        
        let insert = photoAssetTable.insert(assetColumn <- asset.localIdentifier,
                                            mediaSubtypeColumn <- Int64(mediaSubtype),
                                            creationDateColumn <- creationDate,
                                            modificationDateColumn <- modificationDate,
                                            locationLongitudeColumn <- location.longitude,
                                            locationLatitudeColumn <- location.latitude,
                                            favorited <- asset.isFavorite,
                                            hidden <- asset.isHidden,
                                            thumbnailName <- thumbnailLocation.lastPathComponent,
                                            hashColumn <- nil)
        
        let id = try? databaseConnection?.run(insert)
        if let id = id {
            self.logger.info("Inserted photo with ID \(id)")
            
            var insertedImageClassificationCount = 0
            var insertedTextResultClassificationCount = 0
            var insertedResourceCount = 0
            
            for resource in resources {
                let insertResource = photoResourcesTable.insert(
                    assetIdColumn <- id,
                    resourceType <- Int64(resource.0.type.rawValue),
                    uuidColumn <- resource.1)
                let id = try? databaseConnection?.run(insertResource)
                if let id = id {
                    insertedResourceCount += 1
                }
            }

            for result in imageClassificationResults {
                let insert = identifiedObjectsTable.insert(objectNameColumn <- result.identifier,
                                                           confidenceColumn <- Double(result.confidence),
                                                           assetIdColumn <- id)
                let id = try? databaseConnection?.run(insert)
                if let id = id {
                    insertedImageClassificationCount += 1
                }
            }

            for result in textResultClassificationResults {
                for observation in result.topCandidates(10) {
                    let insert = recognizedTextTable.insert(textColumn <- observation.string,
                                                            confidenceColumn <- Double(observation.confidence),
                                                            assetIdColumn <- id)
                    let id = try? databaseConnection?.run(insert)
                    if let id = id {
                        insertedTextResultClassificationCount += 1
                    }
                }
            }

            self.logger.info("Inserted \(insertedResourceCount) resources \(insertedImageClassificationCount) image classification results and \(insertedTextResultClassificationCount) text classification results")

            let query = photoAssetTable.filter(idColumn == id)
            let update = query.update(completedAnalysis <- true)
            let _ = try? databaseConnection?.run(update)

            return .success
        }
        return .failed
    }
    
    enum InsertPhotoResult {
        case success
        case exists
        case failed
    }
}
