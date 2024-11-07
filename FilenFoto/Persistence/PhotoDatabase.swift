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
import InternalCollectionsUtilities

struct DBPhotoAsset : Comparable, Hashable, Identifiable {
    static func < (lhs: DBPhotoAsset, rhs: DBPhotoAsset) -> Bool {
        if lhs.creationDate == rhs.creationDate {
            return lhs.localIdentifier < rhs.localIdentifier
        }
        return lhs.creationDate < rhs.creationDate
    }
    
    static func == (lhs: DBPhotoAsset, rhs: DBPhotoAsset) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
    
    var thumbnailURL: URL {
        PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailFileName)
    }
    
#if DEBUG
    func setId(_ idLocalID: String, idOffset: Int64) -> DBPhotoAsset {
        return DBPhotoAsset(id: id + 50000 + idOffset, localIdentifier: idLocalID, mediaType: mediaType, mediaSubtype: mediaSubtype, creationDate: Date.now - 9999999999999 - TimeInterval(Int(idLocalID) ?? 0), modificationDate: modificationDate, location: location, favorited: favorited, hidden: hidden, thumbnailFileName: thumbnailFileName, burstIdentifier: burstIdentifier, burstSelectionTypes: burstSelectionTypes)
    }
#endif
    
    var isBurst: Bool {
        burstIdentifier != nil
    }
    
    let id: Int64
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let mediaSubtype: PHAssetMediaSubtype
    let creationDate: Date
    let modificationDate: Date
    let location: CLLocation?
    let favorited: Bool
    let hidden: Bool
    let thumbnailFileName: String
    let burstIdentifier: String?
    let burstSelectionTypes: PHAssetBurstSelectionType
}


// Bug in SQLite right now
fileprivate typealias Expression = SQLite.Expression
let photoAssetTable = Table("photoAsset")
let idColumn = Expression<Int64>("id")
let assetColumn = Expression<String>("localIdentifier")
let mediaTypeColumn = Expression<Int64>("mediaType")
let mediaSubtypeColumn = Expression<Int64>("mediaSubtype")
let creationDateColumn = Expression<Date>("creationDate")
let modificationDateColumn = Expression<Date>("modificationDate")
let locationLongitudeColumn = Expression<Double?>("locationLongitude")
let locationLatitudeColumn = Expression<Double?>("locationLatitude")
let completedAnalysis = Expression<Bool>("completedAnalysis")
let favorited = Expression<Bool>("favorited")
let hidden = Expression<Bool>("hidden")
let burstIdentifier = Expression<String?>("burstIdentifier")
let burstSelectionTypes = Expression<Int64>("burstSelectionTypes")
let thumbnailName = Expression<String>("thumbnailLocation")
let thumbnailCacheId = Expression<Int64?>("thumbnailCacheId")

let photoLibrary = Table("photoLibrary")
let burstAssetTable = Table("burstAsset")
// id column
// localIdentifier
// mediaType
// mediaSubtype
// location long and lat
// completed analysis
// burstIdentifier
//let burstSelectionType = Expression<Int64>("burstSelectionTypes")
// thumbnailName
// thumbnailCacheId

let photoResourcesTable = Table("photoResources")
let uuidColumn = Expression<String>("uuid")
let hashColumn = Expression<String>("hash")
let resourceType = Expression<Int64>("resourceType")
let resourceName = Expression<String>("resourceName")

// id
let identifiedObjectsTable = Table("identifiedObjects")
let assetIdColumn = Expression<Int64>("assetId")
let objectNameColumn = Expression<String>("objectName")
let confidenceColumn = Expression<Double>("confidence")

// id
// assetIdColumn
let recognizedTextTable = Table("recognizedText")
let textColumn = Expression<String>("text")

struct SortedArray {
    private var array: Array<DBPhotoAsset> = []
    private var burstAssetDBPhotoAssets: [String:Set<DBPhotoAsset>] = [:]
    
    // Access to the sorted array
    var sortedArray: [DBPhotoAsset] {
        return array
    }
    
    func burstAssets(for burstId: String) -> [DBPhotoAsset] {
        return burstAssetDBPhotoAssets[burstId]?.sorted() ?? []
    }
    
    mutating func removeAll() {
        array.removeAll()
    }
    
    func binSearch(_ element: DBPhotoAsset) -> Int {
        return array.binarySearch(predicate: { $0 > element})
    }
    
    func doesExist(_ element: DBPhotoAsset) -> Bool {
        if let burstId = element.burstIdentifier {
            return (burstAssetDBPhotoAssets[burstId]?.firstIndex(of: element) != nil)
        }
        let binSearchedResult = array.binarySearch(predicate: { $0 > element})
        if array.count > 0 && binSearchedResult < array.count && array[binSearchedResult] == element {
            return true
        }
        return false
    }
    
    // O(lg n)
    // Insert new element and keep array sorted
    mutating func insert(_ element: DBPhotoAsset) {
        let binSearchedResult = array.binarySearch(predicate: { $0 > element})
        if array.count > 0 && binSearchedResult < array.count && array[binSearchedResult] == element {
            return
        }
        
        if let burstId = element.burstIdentifier {
            if burstAssetDBPhotoAssets[burstId] == nil {
                burstAssetDBPhotoAssets[burstId] = [element]
            } else {
                burstAssetDBPhotoAssets[burstId]?.insert(element)
                return
            }
        }
        
        array.insert(element, at: binSearchedResult)
    }
}

extension RandomAccessCollection {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

class PhotoDatabase {
    static let shared = PhotoDatabase()
    static let databaseName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotoDatabase.db", conformingTo: .database)
    private let databaseConnection: Connection?
    
    private init() {
        self.databaseConnection = try? Connection(PhotoDatabase.databaseName.path)
        initiateThousandIndexing()
    }
    
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "PhotoDatabase")
    
    func createPhotoAssetTable() {
        let _ = try? databaseConnection?.run(photoAssetTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetColumn)
            t.column(mediaTypeColumn)
            t.column(mediaSubtypeColumn)
            t.column(creationDateColumn)
            t.column(modificationDateColumn)
            t.column(locationLongitudeColumn)
            t.column(locationLatitudeColumn)
            t.column(favorited)
            t.column(hidden)
            t.column(burstIdentifier)
            t.column(burstSelectionTypes)
            t.column(thumbnailName)
            t.column(thumbnailCacheId)
            t.column(completedAnalysis, defaultValue: false)
            t.foreignKey(thumbnailCacheId, references: photoResourcesTable, idColumn)
        })
        
        let _ = try? databaseConnection?.run(photoLibrary.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .default)
            t.column(creationDateColumn)
            t.foreignKey(idColumn, references: photoAssetTable, idColumn)
        })
        
        let _ = try? databaseConnection?.run(photoLibrary.createIndex(idColumn, creationDateColumn))
        
        let _ = try? databaseConnection?.run(photoResourcesTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetIdColumn)
            t.column(resourceType)
            t.column(uuidColumn)
            t.column(hashColumn)
            t.column(resourceName)
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
        
        let _ = try? databaseConnection?.run(photoAssetTable.createIndex(creationDateColumn.desc))
    }
    
    func filenUUID(for sha256: String) -> String? {
        let query = photoResourcesTable.filter(hashColumn == sha256)
        let result = try? databaseConnection?.prepare(query)
        
        if let result = result {
            for row in result {
                return row[uuidColumn]
            }
        }
        return nil
    }
    
    // Check for completedAnalysis, if photo's completed analysis is false, remove all instances of it from the database
    func doesPhotoExist(_ asset: PHAsset) -> Bool {
        let query = photoAssetTable.filter(assetColumn == asset.localIdentifier)
        let result = try? databaseConnection?.prepare(query)
        if let result = result {
            for row in result {
                if row[completedAnalysis] {
                    return true
                } else {
                    deletePhoto(with: row[idColumn], thumbnailName: row[thumbnailName])
                    return false
                }
            }
        }
        return false
    }
    
    private func deletePhoto(with rowId: Int64, thumbnailName: String) {
        // Delete thumbnail and resources from filen (Only delete resources if they are not used by other photos)
        // TODO: Implement delete in FilenSDK (Only delete resources if they are not used by other photos)
        let _ = try? databaseConnection?.run(photoResourcesTable.filter(assetIdColumn == rowId).delete())
        let _ = try? databaseConnection?.run(identifiedObjectsTable.filter(assetIdColumn == rowId).delete())
        let _ = try? databaseConnection?.run(recognizedTextTable.filter(assetIdColumn == rowId).delete())
        let _ = try? databaseConnection?.run(photoAssetTable.filter(idColumn == rowId).delete())
        let _ = try? databaseConnection?.run(photoLibrary.filter(idColumn == rowId).delete())
        
        // Delete thumbnail
        let thumbnailURL = PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailName)
        let _ = try? FileManager.default.removeItem(at: thumbnailURL)
    }
    
    func getCountOfPhotos() -> Int {
        let query = getBasePhotoLibraryListingQuery().count
        let result = try? databaseConnection?.scalar(query)
        return (result) ?? 0
    }
    
    private let dispatchQueue = DispatchQueue(label: "com.peterfriese.PhotoStreamer.PhotoDatabase")
    
    let cacheOffset = 1000
    private var perThousandDateCache = [Date]()
    private var perThousandIDCache: [Int] = []
    
    private func getBasePhotoLibraryListingQuery() -> Table {
        photoLibrary.select(photoAssetTable[*]).join(photoAssetTable, on: photoAssetTable[idColumn] == photoLibrary[idColumn]).order(photoAssetTable[creationDateColumn].desc, photoAssetTable[idColumn].desc)
    }
    
    private var prePrepStmt: Statement? = nil
    
    private func getDateIDOffsettedQuery(index: Int, offset: Int = 0) -> RowIterator? {
        let ind = index / cacheOffset + offset
        if ind >= perThousandIDCache.count || ind >= perThousandDateCache.count {
            return try? databaseConnection?.prepareRowIterator(getBasePhotoLibraryListingQuery().limit(1, offset: index))
        }
        return try? databaseConnection?.prepareRowIterator("""
        SELECT "photoAsset".*
        FROM "photoLibrary"
        JOIN photoAsset ON photoAsset.id = photoLibrary.id
        WHERE (photoLibrary."creationDate", photoLibrary."id") <= ('\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))', \(perThousandIDCache[ind]))
        ORDER BY photoLibrary."creationDate" DESC, photoLibrary.id DESC
        LIMIT 1
        OFFSET \(index % cacheOffset + -1 * offset * cacheOffset);
        """)
    }
    
    func index(of dbPhotoAsset: DBPhotoAsset) -> Int {
        initiateThousandIndexing()
        let dateNow = Date.now
        var ind = 0
        for i in 0..<perThousandIDCache.count {
            if perThousandDateCache[i] > dbPhotoAsset.creationDate {
                ind = i
            } else {
                break
            }
        }
        var upperBoundQuery: String? = nil
        if ind > 0 {
            upperBoundQuery = """
                AND ("creationDate", "id") <= ('\(SQLite.dateFormatter.string(from: perThousandDateCache[ind - 1]))', \(perThousandIDCache[ind - 1]))
            """
        }
        let query = """
            SELECT 
                COUNT(*)
            FROM photoLibrary
            WHERE ("creationDate", "id") > ('\(SQLite.dateFormatter.string(from: dbPhotoAsset.creationDate))', \(dbPhotoAsset.id))
            \(upperBoundQuery ?? "")
            ORDER BY creationDate DESC, id DESC;
            """
        do {
            let result = try databaseConnection?.scalar(query)
            
            if let result, let index = result as? Int64 {
                print("Finding index took \(Date.now.timeIntervalSince(dateNow))")
                return Int(index) + (ind > 0 ? (ind - 1) * cacheOffset : 0)
            }
            return -1
        } catch {
            logger.error("Failed to get index from id \(error)")
            return -1
        }
    }
    
    @available(*, deprecated, message: "ID based indexing deprecated")
    func getIndexFromId(id: Int) -> Int? {
        let query = """
        WITH RankedPhotos AS (
            SELECT 
                photoLibrary.*, 
                ROW_NUMBER() OVER (ORDER BY photoLibrary."creationDate" DESC, photoLibrary."id" DESC) AS RowIndex
            FROM 
                photoLibrary
            JOIN
                photoAsset ON photoAsset.id = photoLibrary.id
        )
        SELECT 
            RowIndex, id
        FROM 
            RankedPhotos
        WHERE 
            id = ?;
        """
        do {
            let result = try databaseConnection?.prepareRowIterator(query, bindings: [id])
            if let result {
                while let row = try result.failableNext() {
                    if let f = try row.get(Expression<Int?>("RowIndex")) {
                        return f - 1
                    }
                }
            }
        } catch {
            logger.error("Failed to get index from id \(error)")
        }
        return nil
    }
    
    // TODO: Fix burst support
    // TODO: Store this in a table cache
    private func initiateThousandIndexing() {
        if !perThousandDateCache.isEmpty {
            return
        }
        
        databaseConnection?.trace({ print($0) })
        
        let countOfPhotos = getCountOfPhotos()
        var count = 0
        while count < countOfPhotos {
            let now = Date.now
            if count == 0 {
                let query =
                //            (count == 0) ?
                getBasePhotoLibraryListingQuery().limit(1, offset: count)
                //            : getDateIDOffsettedQuery(id: count, offset: -1)
                
                let result = try? self.databaseConnection?.prepare(query)
                
                guard let result else {
                    continue
                }
                
                
                do {
                    for row in result {
                        perThousandDateCache.append(try row.get(photoAssetTable[creationDateColumn]))
                        perThousandIDCache.append(Int(try row.get(photoAssetTable[idColumn])))
                    }
                } catch {
                    print(error)
                }
                
            } else {
                let query = getDateIDOffsettedQuery(index: count, offset: -1)
                
                do {
                    while let row = query?.next() {
                        perThousandDateCache.append(try row.get(creationDateColumn))
                        perThousandIDCache.append(Int(try row.get(idColumn)))
                    }
                } catch {
                    print(error)
                }
            }
            
            count += cacheOffset
            print("Done with \(count) in \(Date.now.timeIntervalSince(now))")
        }
    }
    
    func getDBPhotoSync(atOffset: Int) -> DBPhotoAsset? {
        let dateStart = Date.now
        //        let lastDate = perThousandDateCache[atOffset / cacheOffset]
        let query =
        //        try? databaseConnection?.prepare(getBasePhotoLibraryListingQuery().limit(1, offset: atOffset))
        getDateIDOffsettedQuery(index: atOffset)
        //        getBasePhotoLibraryListingQuery().where(creationDateColumn < lastDate).limit(1, offset: atOffset % cacheOffset)
        
        
        if let result = query {
            while let row = result.next() {
                //            for row in result {
                do {
                    if Date.now.timeIntervalSince(dateStart) > pow(10, -4) {
                        logger.error("\(atOffset) photo retrieval took too long. \(Date.now.timeIntervalSince(dateStart))")
                    }
                    
                    let burstRep = try row.get(burstSelectionTypes)
                    
                    return (DBPhotoAsset(
                        id: try row.get(idColumn),
                        localIdentifier: try row.get(assetColumn),
                        mediaType: PHAssetMediaType(rawValue: Int(try row.get(mediaTypeColumn)))!,
                        mediaSubtype: PHAssetMediaSubtype(rawValue: UInt((try row.get(mediaSubtypeColumn)))),
                        creationDate: try row.get(creationDateColumn),
                        modificationDate: try row.get(modificationDateColumn),
                        location: CLLocation(latitude: try row.get(locationLatitudeColumn) ?? 0, longitude: try row.get(locationLongitudeColumn) ?? 0),
                        favorited: try row.get(favorited),
                        hidden: try row.get(hidden),
                        thumbnailFileName: try row.get(thumbnailName),
                        burstIdentifier: try row.get(burstIdentifier),
                        burstSelectionTypes: PHAssetBurstSelectionType(rawValue: burstRep < 0 ? 0 : UInt(burstRep)))
                    )
                } catch {
                    print("Error \(error)")
                }
            }
        }
        
        return nil
    }
    
    func searchForText(textSearch: String) -> RowIterator? {
        let sql = """
            SELECT *, MAX(confidence) as maxConfidence
                FROM (
                    SELECT assetId, objectName as object, confidence
                    FROM identifiedObjects
                    WHERE objectName LIKE '%' || ? || '%'
                    UNION
                    SELECT assetId, "text" as object, confidence
                    FROM recognizedText 
                    WHERE "text" LIKE '%' || ? || '%'
                )
                JOIN photoAsset ON assetId = photoAsset.id
                GROUP BY assetId
                ORDER BY creationDate DESC;
        """
        do {
            let modifiedTextSearch = textSearch.replacingOccurrences(of: " ", with: "_")
#if DEBUG
            let streamScalar = try databaseConnection?.scalar(sql, [modifiedTextSearch, modifiedTextSearch])
            print("\(streamScalar) results found for search \(textSearch)")
#endif
            let stream = try databaseConnection?.prepareRowIterator(sql, bindings: [modifiedTextSearch, modifiedTextSearch])
            return stream
        } catch {
            logger.error("Failed search \(error)")
        }
        return nil
    }
    
    func insertPhoto(asset: PHAsset, resources: [FilenEquivelentAsset], imageClassificationResults: [VNClassificationObservation], textResultClassificationResults: [VNRecognizedTextObservation], thumbnailLocation: URL) -> InsertPhotoResult {
        return dispatchQueue.sync {
            if doesPhotoExist(asset) {
                return .exists
            }
            
            createPhotoAssetTable()
            
            let mediaSubtype = asset.mediaSubtypes.rawValue
            let creationDate = asset.creationDate ?? Date.now
            let modificationDate = asset.modificationDate ?? Date.now
            let locationLat = asset.location?.coordinate.latitude
            let locationLong = asset.location?.coordinate.longitude
            
            let insert = photoAssetTable.insert(assetColumn <- asset.localIdentifier,
                                                mediaTypeColumn <- Int64(asset.mediaType.rawValue),
                                                mediaSubtypeColumn <- Int64(mediaSubtype),
                                                creationDateColumn <- creationDate,
                                                modificationDateColumn <- modificationDate,
                                                locationLongitudeColumn <- locationLong,
                                                locationLatitudeColumn <- locationLat,
                                                favorited <- asset.isFavorite,
                                                hidden <- asset.isHidden,
                                                burstIdentifier <- asset.burstIdentifier,
                                                burstSelectionTypes <- Int64(asset.burstSelectionTypes.rawValue),
                                                thumbnailName <- thumbnailLocation.lastPathComponent)
            
            if let id = try? databaseConnection?.run(insert) {
                self.logger.info("Inserted photo with ID \(id)")
                
                var insertedImageClassificationCount = 0
                var insertedTextResultClassificationCount = 0
                var insertedResourceCount = 0
                
                var storedThumbnailCacheId: Int64? = nil
                
                for resource in resources {
                    let insertResource = photoResourcesTable.insert(
                        assetIdColumn <- id,
                        resourceType <- Int64(resource.phAssetResource.type.rawValue),
                        hashColumn <- resource.fileHash,
                        uuidColumn <- resource.filenUuid,
                        resourceName <- resource.phAssetResource.originalFilename
                    )
                    let id = try? databaseConnection?.run(insertResource)
                    if let id = id {
                        if storedThumbnailCacheId == nil {
                            storedThumbnailCacheId = id
                        }
                        insertedResourceCount += 1
                    }
                }
                
                //            if let thumbnailCacheFileName {
                //                let update = photoAssetTable.filter(idColumn == id).update(thumbnailCacheName <- thumbnailCacheFileName)
                //                let _ = try? databaseConnection?.run(update)
                //            }
                
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
                let update = query.update(completedAnalysis <- true, thumbnailCacheId <- storedThumbnailCacheId)
                let _ = try? databaseConnection?.run(update)
                
                var didInsertNewLibrary = false
                // If the asset is a burst, check if the burstIdentifier exists in the photoLibrary table, if not, insert it
                if let assetBurstIdentifier = asset.burstIdentifier {
                    let query = getBasePhotoLibraryListingQuery().filter(burstIdentifier == assetBurstIdentifier)
                    let result = try? databaseConnection?.prepare(query)
                    if result == nil {
                        let insert = photoLibrary.insert(
                            idColumn <- id,
                            creationDateColumn <- creationDate
                        )
                        
                        let _ = try? databaseConnection?.run(insert)
                        didInsertNewLibrary = true
                    } else {
                        var hadRow = false
                        for row in result! {
                            hadRow = true
                            if row[burstSelectionTypes] < asset.burstSelectionTypes.rawValue {
                                let remove = photoLibrary.filter(idColumn == row[idColumn]).delete()
                                let _ = try? databaseConnection?.run(remove)
                                
                                let insert = photoLibrary.insert(
                                    idColumn <- id,
                                    creationDateColumn <- creationDate
                                )
                                let _ = try? databaseConnection?.run(insert)
                            }
                        }
                        if !hadRow {
                            let insert = photoLibrary.insert(
                                idColumn <- id,
                                creationDateColumn <- creationDate
                            )
                            
                            let _ = try? databaseConnection?.run(insert)
                            didInsertNewLibrary = true
                        }
                    }
                } else {
                    let insert = photoLibrary.insert(
                        idColumn <- id,
                        creationDateColumn <- creationDate
                    )
                    let _ = try? databaseConnection?.run(insert)
                    didInsertNewLibrary = true
                }
                
                perThousandIDCache.removeAll()
                perThousandDateCache.removeAll()
                initiateThousandIndexing()
                
                return .success(DBPhotoAsset(
                    id: id,
                    localIdentifier: asset.localIdentifier,
                    mediaType: asset.mediaType,
                    mediaSubtype: asset.mediaSubtypes,
                    creationDate: creationDate,
                    modificationDate: modificationDate,
                    location: asset.location,
                    favorited: asset.isFavorite,
                    hidden: asset.isHidden,
                    thumbnailFileName: thumbnailLocation.lastPathComponent,
                    burstIdentifier: asset.burstIdentifier,
                    burstSelectionTypes: asset.burstSelectionTypes),
                                didInsertNewLibrary
                )
            }
            return .failed
        }
    }
    
    func getFilenUUID(for asset: DBPhotoAsset, mediaType: PHAssetResourceType) -> [DBPhotoResourceResult] {
        let query = photoResourcesTable.filter(assetIdColumn == asset.id && resourceType == Int64(mediaType.rawValue))
        var stringResult = [DBPhotoResourceResult]()
        do {
            let result = try databaseConnection?.prepare(query)
            if result == nil {
                return stringResult
            }
            for row in result! {
                let rName = try row.get(resourceName)
                stringResult.append(DBPhotoResourceResult(
                    id: try row.get(idColumn),
                    assetId: try row.get(assetIdColumn),
                    uuid: try row.get(uuidColumn),
                    resourceType: PHAssetResourceType(rawValue: Int(try row.get(resourceType)))!,
                    sha256: try row.get(hashColumn),
                    resourceExtension: String(rName.suffix(from: rName.index(rName.lastIndex(of: ".") ?? rName.endIndex, offsetBy: 1)))
                ))
            }
        } catch {
            logger.log("Asset resource query for \(mediaType.rawValue) failed: \(error)")
        }
        return stringResult
    }
    
    func getMostPopularObjects() -> [String] {
        let sql = """
            SELECT objectName, SUM(confidence) as totalConfidence
            FROM identifiedObjects
            GROUP BY objectName
            ORDER BY SUM(confidence) DESC
            LIMIT 15;
        """
        
        var res = [String]()
        do {
            let stream = try databaseConnection?.prepareRowIterator(sql)
            if let stream {
                while let row = try stream.failableNext() {
                    res.append(try row.get(objectNameColumn))
                }
            }
        } catch {
            logger.error("Failed search \(error)")
        }
        return res
    }
    
    func unsafeInsertAsset(asset: ExtractedFilenAssetInfo) -> Int64? {
        createPhotoAssetTable()
        let insert = photoAssetTable.insert(assetColumn <- asset.localIdentifier,
                                            mediaTypeColumn <- Int64(asset.mediaType.rawValue),
                                            mediaSubtypeColumn <- Int64(asset.mediaSubtype.rawValue),
                                            creationDateColumn <- asset.creationDate,
                                            modificationDateColumn <- asset.modificationDate,
                                            locationLongitudeColumn <- asset.location?.coordinate.longitude,
                                            locationLatitudeColumn <- asset.location?.coordinate.latitude,
                                            favorited <- false,
                                            hidden <- false,
                                            burstIdentifier <- asset.burstIdentifier,
                                            burstSelectionTypes <- Int64(asset.burstSelectionTypes.rawValue),
                                            thumbnailName <- "")
        if let id = try? databaseConnection?.run(insert) {
            return id
        }
        
        return nil
    }
    
    func doesResourceExist(_ asset: ExtractedFilenAssetInfo, _ assetRowId: Int64) -> Bool {
        let query = photoResourcesTable.filter(assetIdColumn == assetRowId && hashColumn == asset.sha256)
        let result = try? databaseConnection?.prepare(query)
        if let result {
            for _ in result {
                return true
            }
        }
        return false
    }
    
    func insertPhoto(asset: ExtractedFilenAssetInfo, filenUUID: String, fileName: String, assetRowId: Int64, imageClassificationResults: [VNClassificationObservation], textResultClassificationResults: [VNRecognizedTextObservation], thumbnailLocation: URL) -> InsertPhotoResult {
        return dispatchQueue.sync { () -> InsertPhotoResult in
            createPhotoAssetTable()
            if doesResourceExist(asset, assetRowId) {
                // remove
                let deleteQuery = photoResourcesTable.filter(assetIdColumn == assetRowId && hashColumn == asset.sha256).delete()
                let _ = try? databaseConnection?.run(deleteQuery)
            }
            
            var mediaSubtype = asset.mediaSubtype.rawValue
            let creationDate = asset.creationDate
            let modificationDate = asset.modificationDate
            let locationLat = asset.location?.coordinate.latitude
            let locationLong = asset.location?.coordinate.longitude
            
            // Get current DBPhotoAsset
            guard let row = try? databaseConnection?.prepare(photoAssetTable.filter(idColumn == assetRowId)).makeIterator().next() else {
                logger.error("Failed to get current DBPhotoAsset")
                return .failed
            }
            
            do {
                let currentDBPhotoAsset = DBPhotoAsset(
                    id: try row.get(idColumn),
                    localIdentifier: try row.get(assetColumn),
                    mediaType: PHAssetMediaType(rawValue: Int(try row.get(mediaTypeColumn)))!,
                    mediaSubtype: PHAssetMediaSubtype(rawValue: UInt((try row.get(mediaSubtypeColumn)))),
                    creationDate: try row.get(creationDateColumn),
                    modificationDate: try row.get(modificationDateColumn),
                    location: CLLocation(latitude: try row.get(locationLatitudeColumn) ?? 0, longitude: try row.get(locationLongitudeColumn) ?? 0),
                    favorited: try row.get(favorited),
                    hidden: try row.get(hidden),
                    thumbnailFileName: try row.get(thumbnailName),
                    burstIdentifier: try row.get(burstIdentifier),
                    burstSelectionTypes: PHAssetBurstSelectionType(rawValue: UInt(try row.get(burstSelectionTypes)))
                )
                
                mediaSubtype = asset.mediaSubtype.union(currentDBPhotoAsset.mediaSubtype).rawValue
                
                // Compare creation, modification, long, lat
                if currentDBPhotoAsset.creationDate != creationDate || currentDBPhotoAsset.modificationDate != modificationDate || currentDBPhotoAsset.location?.coordinate.latitude != locationLat || currentDBPhotoAsset.location?.coordinate.longitude != locationLong {
                    logger.error("Asset information does not match, will update asset")
                    logger.error("Current: \(currentDBPhotoAsset.localIdentifier)\n\nNew: \(asset.localIdentifier)")
                }
                
                var thumbnailFileName = currentDBPhotoAsset.thumbnailFileName
                let shouldUpdateAssetStats: Bool
                if thumbnailFileName.isEmpty{
                    shouldUpdateAssetStats = true
                } else if let currentThumbnailResourceTypeRaw = try? databaseConnection?.prepare(photoResourcesTable.filter(assetIdColumn == assetRowId)).makeIterator().next()?.get(resourceType), let currentThumbnailResourceType = PHAssetResourceType(rawValue: Int(currentThumbnailResourceTypeRaw)) {
                    shouldUpdateAssetStats = thumbnailCandidacyComparison(asset.resourceType, currentThumbnailResourceType)
                } else {
                    shouldUpdateAssetStats = false
                }
                
                if shouldUpdateAssetStats {
                    thumbnailFileName = thumbnailLocation.lastPathComponent
                }
                
                let update = photoAssetTable.filter(idColumn == assetRowId).update(
                    creationDateColumn <- creationDate,
                    modificationDateColumn <- modificationDate,
                    locationLongitudeColumn <- locationLong,
                    locationLatitudeColumn <- locationLat)
                
                if let _ = try? databaseConnection?.run(update) {
                    let id = assetRowId
                    self.logger.info("Updated photo with ID \(id)")
                    
                    var insertedImageClassificationCount = 0
                    var insertedTextResultClassificationCount = 0
                    
                    var storedThumbnailCacheId: Int64? = nil
                    
                    let insertResource = photoResourcesTable.insert(
                        assetIdColumn <- Int64(id),
                        resourceType <- Int64(asset.resourceType.rawValue),
                        hashColumn <- asset.sha256,
                        uuidColumn <- filenUUID,
                        resourceName <- fileName
                    )
                    if let id = try? databaseConnection?.run(insertResource), shouldUpdateAssetStats {
                        if storedThumbnailCacheId == nil {
                            storedThumbnailCacheId = id
                        }
                    }
                    
                    if shouldUpdateAssetStats {
                        // Remove all previous image and text classification results
                        let deleteIdentifiedObjects = identifiedObjectsTable.filter(assetIdColumn == Int64(id)).delete()
                        let deleteRecognizedText = recognizedTextTable.filter(assetIdColumn == Int64(id)).delete()
                        
                        let _ = try? databaseConnection?.run(deleteIdentifiedObjects)
                        let _ = try? databaseConnection?.run(deleteRecognizedText)
                        
                        for result in imageClassificationResults {
                            let insert = identifiedObjectsTable.insert(objectNameColumn <- result.identifier,
                                                                       confidenceColumn <- Double(result.confidence),
                                                                       assetIdColumn <- Int64(id))
                            let id = try? databaseConnection?.run(insert)
                            if let id = id {
                                insertedImageClassificationCount += 1
                            }
                        }
                        
                        for result in textResultClassificationResults {
                            for observation in result.topCandidates(10) {
                                let insert = recognizedTextTable.insert(textColumn <- observation.string,
                                                                        confidenceColumn <- Double(observation.confidence),
                                                                        assetIdColumn <- Int64(id))
                                let id = try? databaseConnection?.run(insert)
                                if let id = id {
                                    insertedTextResultClassificationCount += 1
                                }
                            }
                        }
                    }
                    
                    self.logger.info("Inserted 1 resource \(insertedImageClassificationCount) image classification results and \(insertedTextResultClassificationCount) text classification results")
                    
                    let query = photoAssetTable.filter(idColumn == Int64(id))
                    let update = query.update(completedAnalysis <- true,
                                              thumbnailName <- thumbnailFileName,
                                              thumbnailCacheId <- storedThumbnailCacheId)
                    let _ = try? databaseConnection?.run(update)
                    
                    var didInsertNewLibrary = false
                    // If the asset is a burst, check if the burstIdentifier exists in the photoLibrary table, if not, insert it
                    if let assetBurstIdentifier = asset.burstIdentifier {
                        let query = getBasePhotoLibraryListingQuery().filter(burstIdentifier == assetBurstIdentifier)
                        let result = try? databaseConnection?.prepare(query)
                        if result == nil {
                            let insert = photoLibrary.insert(
                                idColumn <- Int64(id),
                                creationDateColumn <- creationDate
                            )
                            
                            let _ = try? databaseConnection?.run(insert)
                            didInsertNewLibrary = true
                        } else {
                            var hadRow = false
                            for row in result! {
                                hadRow = true
                                if row[burstSelectionTypes] < asset.burstSelectionTypes.rawValue {
                                    let remove = photoLibrary.filter(idColumn == row[idColumn]).delete()
                                    let _ = try? databaseConnection?.run(remove)
                                    
                                    let insert = photoLibrary.insert(
                                        idColumn <- Int64(id),
                                        creationDateColumn <- creationDate
                                    )
                                    let _ = try? databaseConnection?.run(insert)
                                }
                            }
                            if !hadRow {
                                let insert = photoLibrary.insert(
                                    idColumn <- Int64(id),
                                    creationDateColumn <- creationDate
                                )
                                
                                let _ = try? databaseConnection?.run(insert)
                                didInsertNewLibrary = true
                            }
                        }
                    } else {
                        let insert = photoLibrary.insert(
                            idColumn <- Int64(id),
                            creationDateColumn <- creationDate
                        )
                        let _ = try? databaseConnection?.run(insert)
                        didInsertNewLibrary = true
                    }
                    
                    perThousandIDCache.removeAll()
                    perThousandDateCache.removeAll()
                    initiateThousandIndexing()
                    
                    return .success(DBPhotoAsset(
                        id: Int64(id),
                        localIdentifier: asset.localIdentifier,
                        mediaType: asset.mediaType,
                        mediaSubtype: PHAssetMediaSubtype(rawValue: mediaSubtype),
                        creationDate: creationDate,
                        modificationDate: modificationDate,
                        location: asset.location,
                        favorited: currentDBPhotoAsset.favorited,
                        hidden: currentDBPhotoAsset.hidden,
                        thumbnailFileName: thumbnailLocation.lastPathComponent,
                        burstIdentifier: asset.burstIdentifier,
                        burstSelectionTypes: asset.burstSelectionTypes),
                                    didInsertNewLibrary
                    )
                }
            } catch {
                logger.error("Failed to update asset \(error)")
            }
            
            return .failed
        }
    }
    
    struct DBPhotoResourceResult {
        let id: Int64
        let assetId: Int64
        let uuid: String
        let resourceType: PHAssetResourceType
        let sha256: String
        let resourceExtension: String
    }
    
    enum InsertPhotoResult {
        case success(DBPhotoAsset, Bool)
        case exists
        case failed
    }
}
