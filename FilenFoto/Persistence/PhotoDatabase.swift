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
import NaturalLanguage

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


// Bug in SQLite right now
fileprivate typealias Expression = SQLite.Expression
fileprivate let photoAssetTable = Table("photoAsset")
fileprivate let idColumn = Expression<Int64>("id")
fileprivate let assetColumn = Expression<String>("localIdentifier")
fileprivate let mediaTypeColumn = Expression<Int64>("mediaType")
fileprivate let mediaSubtypeColumn = Expression<Int64>("mediaSubtype")
fileprivate let creationDateColumn = Expression<Date>("creationDate")
fileprivate let modificationDateColumn = Expression<Date>("modificationDate")
fileprivate let locationLongitudeColumn = Expression<Double?>("locationLongitude")
fileprivate let locationLatitudeColumn = Expression<Double?>("locationLatitude")
fileprivate let completedAnalysis = Expression<Bool>("completedAnalysis")
fileprivate let favoritedColumn = Expression<Bool>("favorited")
fileprivate let hiddenColumn = Expression<Bool>("hidden")
fileprivate let burstIdentifierColumn = Expression<String?>("burstIdentifier")
fileprivate let burstSelectionTypesColumn = Expression<Int64>("burstSelectionTypes")
fileprivate let thumbnailName = Expression<String>("thumbnailLocation")
fileprivate let thumbnailCacheId = Expression<Int64?>("thumbnailCacheId")

fileprivate let photoLibrary = Table("photoLibrary")
fileprivate let burstAssetTable = Table("burstAsset")
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

fileprivate let photoResourcesTable = Table("photoResources")
fileprivate let uuidColumn = Expression<String>("uuid")
fileprivate let hashColumn = Expression<String>("hash")
fileprivate let resourceType = Expression<Int64>("resourceType")
fileprivate let resourceName = Expression<String>("resourceName")

// id
fileprivate let identifiedSearchGroups = Table("identifiedSearchGroups")
fileprivate let searchGroupNormalized = Expression<String>("tagName")
fileprivate let categoryColumn = Expression<Int64>("category")

fileprivate let assetGroupRelation = Table("assetGroupRelation")
fileprivate let assetIdColumn = Expression<Int64>("assetId")
fileprivate let groupIdColumn = Expression<Int64>("groupId")
fileprivate let originalTagName = Expression<String>("originalTagName")
fileprivate let confidenceColumn = Expression<Double>("confidence")

enum SearchTagCategory: Int64 {
    case text = 0
    case object = 1
    case date = 2
    case locationCity = 3
    case locationCountry = 4
    case locationAdmin = 5
}

class PhotoDatabase {
    static let shared = PhotoDatabase()
    static let databaseName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotoDatabase.db", conformingTo: .database)
    private let databaseConnection: Connection?
    
    private init() {
        self.databaseConnection = try? Connection(PhotoDatabase.databaseName.path)
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
            t.column(favoritedColumn)
            t.column(hiddenColumn)
            t.column(burstIdentifierColumn)
            t.column(burstSelectionTypesColumn)
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
        
        let _ = try? databaseConnection?.run(photoResourcesTable.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(assetIdColumn)
            t.column(resourceType)
            t.column(uuidColumn)
            t.column(hashColumn)
            t.column(resourceName)
            t.foreignKey(assetIdColumn, references: photoAssetTable, idColumn)
        })
        
        let _ = try? databaseConnection?.run(identifiedSearchGroups.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(searchGroupNormalized)
            t.column(categoryColumn)
        })
        
        let _ = try? databaseConnection?.run(assetGroupRelation.create(ifNotExists: true) { t in
            t.column(assetIdColumn)
            t.column(groupIdColumn)
            t.column(confidenceColumn)
            t.column(originalTagName)
            t.foreignKey(assetIdColumn, references: photoAssetTable, idColumn)
            t.foreignKey(groupIdColumn, references: identifiedSearchGroups, idColumn)
        })
        
        let _ = try? databaseConnection?.run(photoAssetTable.createIndex(creationDateColumn.desc, idColumn.desc))
        let _ = try? databaseConnection?.run(photoLibrary.createIndex(creationDateColumn.desc, idColumn.desc))
        let _ = try? databaseConnection?.run(identifiedSearchGroups.createIndex(searchGroupNormalized.asc))
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
//        let _ = try? databaseConnection?.run(identifiedObjectsTable.filter(assetIdColumn == rowId).delete())
//        let _ = try? databaseConnection?.run(recognizedTextTable.filter(assetIdColumn == rowId).delete())
        let _ = try? databaseConnection?.run(assetGroupRelation.filter(assetIdColumn == rowId).delete())
        let _ = try? databaseConnection?.run(photoAssetTable.filter(idColumn == rowId).delete())
        let _ = try? databaseConnection?.run(photoLibrary.filter(idColumn == rowId).delete())
        
        // Delete thumbnail
        let thumbnailURL = PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailName)
        let _ = try? FileManager.default.removeItem(at: thumbnailURL)
    }
    
    func getCountOfPhotos() -> Int {
        let dateNow = Date.now
        let query = photoLibrary.count
        let result = try? databaseConnection?.scalar(query)
        print("Counting took \(Date.now.timeIntervalSince(dateNow))")
        return (result) ?? 0
    }
    
    private let dispatchQueue = DispatchQueue(label: "com.peterfriese.PhotoStreamer.PhotoDatabase")
    
    let cacheOffset = 1000
    @MainActor private var perThousandDateCache = [Date]()
    @MainActor private var perThousandIDCache: [Int] = []
    
    private func getBasePhotoLibraryListingQuery() -> Table {
        photoLibrary.select(photoAssetTable[*]).join(photoAssetTable, on: photoAssetTable[idColumn] == photoLibrary[idColumn]).order(photoAssetTable[creationDateColumn].desc, photoAssetTable[idColumn].desc)
    }
    
    private var prePrepStmt: Statement? = nil
    
    @MainActor private func getDateIDOffsettedQuery(index: Int, offset: Int = 0) -> RowIterator? {
        let ind = index / cacheOffset + offset
        if ind >= perThousandIDCache.count || ind >= perThousandDateCache.count {
            return try? databaseConnection?.prepareRowIterator(getBasePhotoLibraryListingQuery().limit(1, offset: index))
        }
//        return try? databaseConnection?.prepareRowIterator("""
//        SELECT "photoAsset".*
//        FROM "photoLibrary"
//        JOIN photoAsset ON photoAsset.id = photoLibrary.id
//        WHERE (photoLibrary."creationDate", photoLibrary."id") <= ('\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))', \(perThousandIDCache[ind]))
//        ORDER BY photoLibrary."creationDate" DESC, photoLibrary.id ASC
//        LIMIT 1
//        OFFSET \(index % cacheOffset + -1 * offset * cacheOffset);
//        """)

//        return try? databaseConnection?.prepareRowIterator("""
//        SELECT "photoAsset".*
//        FROM "photoLibrary"
//        JOIN photoAsset ON photoAsset.id = photoLibrary.id
//        WHERE photoLibrary."creationDate" < '\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))'
//        OR (photoLibrary."creationDate" == '\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))' AND photoLibrary."id" >= \(perThousandIDCache[ind]))
//        ORDER BY photoLibrary."creationDate" DESC, photoLibrary.id ASC
//        LIMIT 1
//        OFFSET \(index % cacheOffset + -1 * offset * cacheOffset);
//        """)
        
        /*
         WITH res AS (SELECT *
         FROM "photoLibrary"
         WHERE (photoLibrary."creationDate" = '2023-07-02T15:30:06.000' AND photoLibrary.id <= 339064)
         UNION ALL
         SELECT *
         FROM "photoLibrary"
         WHERE photoLibrary."creationDate" < '2023-07-02T15:30:06.000'
         ORDER BY photoLibrary."creationDate" DESC, photoLibrary.id DESC
         LIMIT 1
         OFFSET 642)
         SELECT photoAsset.*
         FROM res
         JOIN photoAsset ON photoAsset.id = res.id;
         */
        return try? databaseConnection?.prepareRowIterator("""
        WITH res AS (SELECT *
        FROM "photoLibrary"
        WHERE (photoLibrary."creationDate" = '\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))' AND photoLibrary.id <= \(perThousandIDCache[ind]))
        UNION ALL
        SELECT *
        FROM "photoLibrary"
        WHERE photoLibrary."creationDate" < '\(SQLite.dateFormatter.string(from: perThousandDateCache[ind]))'
        ORDER BY photoLibrary."creationDate" DESC, photoLibrary.id DESC
        LIMIT 1
        OFFSET \(index % cacheOffset + -1 * offset * cacheOffset))
        SELECT photoAsset.*
        FROM res
        JOIN photoAsset ON photoAsset.id = res.id;
        """)
    }
    
    @MainActor func index(of dbPhotoAsset: DBPhotoAsset) -> Int {
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
    
    // TODO: Store this in a table cache
    @MainActor private func initiateThousandIndexing() {
        if !perThousandDateCache.isEmpty {
            return
        }
        
//        try? self.databaseConnection?.trace { print($0) }
        
        let countOfPhotos = getCountOfPhotos()
        var count = 0
        while count < countOfPhotos {
            let now = Date.now
            if count == 0 {
                let query = (count == 0) ?
                try? self.databaseConnection?.prepareRowIterator(getBasePhotoLibraryListingQuery().limit(1, offset: count))
                : getDateIDOffsettedQuery(index: count, offset: -1)
                
                let result = query
                
                guard let result else {
                    continue
                }
                
                
                do {
                    if let row = try? result.failableNext() {
//                    for row in result {
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
    
    @MainActor var photoCache: [Int: DBPhotoAsset] = [:]
    
    @MainActor func getDBPhotoSync(atOffset: Int) -> DBPhotoAsset? {
        if let cachedPhoto = photoCache[atOffset] {
            return cachedPhoto
        }
        print("Cache no hit Getting photo at \(atOffset)")
        initiateThousandIndexing()
        let dateStart = Date.now
        //        let lastDate = perThousandDateCache[atOffset / cacheOffset]
        let query = getDateIDOffsettedQuery(index: atOffset)
        
        if let result = query {
            while let row = result.next() {
                //            for row in result {
                do {
                    if Date.now.timeIntervalSince(dateStart) > pow(10, -3) {
                        logger.error("\(atOffset) photo retrieval took too long. \(Date.now.timeIntervalSince(dateStart))")
                    }
                    
                    let dbPhotoAsset = DBPhotoAsset(row: row)
//                    let burstRep = try row.get(burstSelectionTypesColumn)
                    photoCache[atOffset] = dbPhotoAsset
#if DEBUG
//                    let ind = index(of: dbPhotoAsset)
//                    assert(ind == atOffset, "Indexing error \(ind) != \(atOffset)")
#endif
                    return dbPhotoAsset
                } catch {
                    print("Error \(error)")
                }
            }
        }
        
        return nil
    }
    
    
    func searchForText(textSearch: String) -> RowIterator? {
        let startTime = Date.now
        
        let tokens = tokenize(for: textSearch)
        var query = identifiedSearchGroups
        for token in tokens {
            query = query.filter(searchGroupNormalized.like("\(normalize(tag: token))%"))
        }
        query = query.join(assetGroupRelation, on: groupIdColumn == identifiedSearchGroups[idColumn])
            .join(photoAssetTable, on: assetIdColumn == photoAssetTable[idColumn])
            .group(photoAssetTable[idColumn])
            .order(photoAssetTable[creationDateColumn].desc, photoAssetTable[idColumn].desc)
            
        do {
            let stream = try databaseConnection?.prepareRowIterator(query)
            print("Search took \(Date.now.timeIntervalSince(startTime))")
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
                                                favoritedColumn <- asset.isFavorite,
                                                hiddenColumn <- asset.isHidden,
                                                burstIdentifierColumn <- asset.burstIdentifier,
                                                burstSelectionTypesColumn <- Int64(asset.burstSelectionTypes.rawValue),
                                                thumbnailName <- thumbnailLocation.lastPathComponent)
            
            if let id = try? databaseConnection?.run(insert) {
                self.logger.info("Inserted photo with ID \(id)")
                
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
                
                let insertedImageClassificationCount = insertImageClassifications(id, imageClassificationResults: imageClassificationResults)
                let insertedTextResultClassificationCount = insertTextClassifications(id, textClassificationResults: textResultClassificationResults)
                
                self.logger.info("Inserted \(insertedResourceCount) resources \(insertedImageClassificationCount) image classification results and \(insertedTextResultClassificationCount) text classification results")
                
                let query = photoAssetTable.filter(idColumn == id)
                let update = query.update(completedAnalysis <- true, thumbnailCacheId <- storedThumbnailCacheId)
                let _ = try? databaseConnection?.run(update)
                
                let didInsertNewLibrary = insertIntoPhotoLibrary(burstIdentifier: asset.burstIdentifier, burstSelectionTypes: asset.burstSelectionTypes, id: id, creationDate: creationDate)
                
                insertPhotoMetadataTags(id, creationDate: creationDate, location: asset.location)
                
                resetPhotoIndexCache()
                
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
    
    func mostPopular(category: SearchTagCategory) -> [String] {
        let query = identifiedSearchGroups.select(searchGroupNormalized, confidenceColumn.sum)
            .join(assetGroupRelation, on: groupIdColumn == identifiedSearchGroups[idColumn])
            .where(categoryColumn == category.rawValue)
            .group(searchGroupNormalized)
            .order(confidenceColumn.sum.desc)
            .limit(15)
        
        let dateTime = Date.now
        var res = [String]()
        do {
            let result = try databaseConnection?.prepare(query)
            
            if let result {
                for row in result {
                    res.append(try row.get(searchGroupNormalized))
                }
            }
        } catch {
            logger.error("Failed to get most popular objects \(error)")
        }
        print("Most popular search for \(category) took \(Date.now.timeIntervalSince(dateTime))")
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
                                            favoritedColumn <- false,
                                            hiddenColumn <- false,
                                            burstIdentifierColumn <- asset.burstIdentifier,
                                            burstSelectionTypesColumn <- Int64(asset.burstSelectionTypes.rawValue),
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
    
    // replace umlauts or accents
    private func normalize(tag: String) -> String {
        tag.strippingDiacritics.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    private func addTagGroupIfNotExists(_ tagNameUnnormalized: String, category: SearchTagCategory) throws -> Int64 {
        guard let databaseConnection else { throw PhotoSyncError.unknown("Database connection is nil") }
        let tagName = normalize(tag: tagNameUnnormalized)
        
        let query = identifiedSearchGroups.filter(searchGroupNormalized == tagName && categoryColumn == category.rawValue)
        let result = try? databaseConnection.pluck(query)
        
        if let result {
            return result[idColumn]
        } else {
            let insert = identifiedSearchGroups.insert(searchGroupNormalized <- tagName, categoryColumn <- category.rawValue)
            return try databaseConnection.run(insert)
        }
    }
    
    private func relateAssetIdToTag(_ assetId: Int64, tag: String, category: SearchTagCategory, confidence: Double) {
        do {
            let tagId = try addTagGroupIfNotExists(tag, category: category)
            let insert = assetGroupRelation.insert(
                assetIdColumn <- assetId,
                groupIdColumn <- tagId,
                confidenceColumn <- confidence,
                originalTagName <- tag
            )
            
            let _ = try databaseConnection?.run(insert)
        } catch {
            logger.error("Failed to relate asset ID to tag \(error)")
        }
    }
    
    private func insertImageClassifications(_ id: Int64, imageClassificationResults: [VNClassificationObservation]) -> Int {
        var insertedImageClassificationCount = 0
        
        for result in imageClassificationResults {
            relateAssetIdToTag(id, tag: result.identifier, category: .object, confidence: Double(result.confidence))
            insertedImageClassificationCount += 1
        }
        
        return insertedImageClassificationCount
    }
    
    private let tokenizerDispatchQueue = DispatchQueue(label: "com.hunterhan.PhotoDatabase.NaturalLanguageTokenizer")
    private let tokenizer = NLTokenizer(unit: .word)
    private func tokenize(for text: String) -> [String] {
        return tokenizerDispatchQueue.sync {
            tokenizer.string = text
            return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
        }
    }
    
    private func insertTextClassifications(_ id: Int64, textClassificationResults: [VNRecognizedTextObservation]) -> Int {
        var insertedTextResultClassificationCount = 0
        for result in textClassificationResults {
            let topCandidates = result.topCandidates(10)
            let maxConfidence = topCandidates.first?.confidence ?? 0.0
            let wordCandidates = topCandidates.filter { $0.confidence == maxConfidence }
            
            // Select longest candidate
            let longestCandidate = wordCandidates.max { $0.string.count < $1.string.count }
            
            if let longestCandidate {
                let tokens = tokenize(for: longestCandidate.string)
                for token in tokens {
                    relateAssetIdToTag(id, tag: token, category: .text, confidence: Double(longestCandidate.confidence))
                }
                insertedTextResultClassificationCount += 1
            }
        }
        
        return insertedTextResultClassificationCount
    }
    
    private func season(for date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        // Define the start dates for each season
        let winterStart = calendar.date(from: DateComponents(year: year, month: 12, day: 21))!
        let springStart = calendar.date(from: DateComponents(year: year, month: 3, day: 21))!
        let summerStart = calendar.date(from: DateComponents(year: year, month: 6, day: 21))!
        let fallStart = calendar.date(from: DateComponents(year: year, month: 9, day: 21))!
        
        // Check which season the date falls into
        if date >= winterStart || date < springStart {
            return "Winter"
        } else if date >= springStart && date < summerStart {
            return "Spring"
        } else if date >= summerStart && date < fallStart {
            return "Summer"
        } else {
            return "Fall"
        }
    }
    
    private func insertPhotoMetadataTags(_ id: Int64, creationDate: Date, location: CLLocation?) {
        if let location, let (cityName, adminName, countryName) = ReverseGeolocator.shared.reverseGeolocate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) {
            relateAssetIdToTag(id, tag: cityName, category: .locationCity, confidence: 1.0)
            relateAssetIdToTag(id, tag: adminName, category: .locationAdmin, confidence: 1.0)
            relateAssetIdToTag(id, tag: countryName, category: .locationCountry, confidence: 1.0)
        }
        
        // Month, Year, and Season
        let calendar = Calendar.current
        let month = calendar.component(.month, from: creationDate)
        let year = calendar.component(.year, from: creationDate)
        let season = season(for: creationDate)
        
        relateAssetIdToTag(id, tag: "\(month)", category: .date, confidence: 1.0)
        relateAssetIdToTag(id, tag: "\(year)", category: .date, confidence: 1.0)
        relateAssetIdToTag(id, tag: season, category: .date, confidence: 1.0)
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
            
            let currentDBPhotoAsset = DBPhotoAsset(row: row)
            
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
                    let deleteIdentifiedObjects = assetGroupRelation.filter(assetIdColumn == id).delete()
                    let _ = try? databaseConnection?.run(deleteIdentifiedObjects)
                    
                    insertedImageClassificationCount = insertImageClassifications(id, imageClassificationResults: imageClassificationResults)
                    insertedTextResultClassificationCount = insertTextClassifications(id, textClassificationResults: textResultClassificationResults)
                }
                
                self.logger.info("Inserted 1 resource \(insertedImageClassificationCount) image classification results and \(insertedTextResultClassificationCount) text classification results")
                
                let query = photoAssetTable.filter(idColumn == Int64(id))
                let update = query.update(completedAnalysis <- true,
                                          thumbnailName <- thumbnailFileName,
                                          thumbnailCacheId <- storedThumbnailCacheId)
                let _ = try? databaseConnection?.run(update)
                
                let didInsertNewLibrary = insertIntoPhotoLibrary(burstIdentifier: asset.burstIdentifier, burstSelectionTypes: asset.burstSelectionTypes, id: Int64(id), creationDate: creationDate)
                
                insertPhotoMetadataTags(Int64(id), creationDate: creationDate, location: asset.location)

                resetPhotoIndexCache()
                
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
            
            return .failed
        }
    }
    
    private func resetPhotoIndexCache() {
        DispatchQueue.main.sync {
            perThousandIDCache.removeAll()
            perThousandDateCache.removeAll()
            photoCache.removeAll()
            initiateThousandIndexing()
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
    
    /// Checks burst identifiers and decides whether to update thumbnail or insert into photoLibrary
    private func insertIntoPhotoLibrary(burstIdentifier: String?, burstSelectionTypes: PHAssetBurstSelectionType?, id: Int64, creationDate: Date) -> Bool {
        // If the asset is a burst, check if the burstIdentifier exists in the photoLibrary table, if not, insert it
        if let assetBurstIdentifier = burstIdentifier, let burstSelectionTypes {
            let query = getBasePhotoLibraryListingQuery().filter(burstIdentifierColumn == assetBurstIdentifier)
            let result = try? databaseConnection?.prepare(query)
            if result == nil {
                let insert = photoLibrary.insert(
                    idColumn <- id,
                    creationDateColumn <- creationDate
                )
                
                let _ = try? databaseConnection?.run(insert)
                return true
            } else {
                var hadRow = false
                for row in result! {
                    hadRow = true
                    if row[burstSelectionTypesColumn] < burstSelectionTypes.rawValue {
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
                    return true
                }
            }
        } else {
            let insert = photoLibrary.insert(
                idColumn <- Int64(id),
                creationDateColumn <- creationDate
            )
            let _ = try? databaseConnection?.run(insert)
            return true
        }
        
        return false
    }
}

extension DBPhotoAsset {
    init(row: Row) {
        var location: CLLocation?
        
        if let lat = row[locationLatitudeColumn], let long = row[locationLongitudeColumn] {
            location = CLLocation(latitude: lat, longitude: long)
        }
        
        self.id = (try? row.get(photoAssetTable[idColumn])) ?? row[idColumn]
        self.localIdentifier = row[assetColumn]
        self.mediaType = PHAssetMediaType(rawValue: Int(row[mediaTypeColumn]))!
        self.mediaSubtype = PHAssetMediaSubtype(rawValue: UInt(row[mediaSubtypeColumn]))
        self.creationDate = row[creationDateColumn]
        self.modificationDate = row[modificationDateColumn]
        self.location = location
        self.favorited = row[favoritedColumn]
        self.hidden = row[hiddenColumn]
        self.thumbnailFileName = row[thumbnailName]
        self.burstIdentifier = row[burstIdentifierColumn]
        self.burstSelectionTypes = PHAssetBurstSelectionType(rawValue: UInt(row[burstSelectionTypesColumn]))
    }
}

extension StringProtocol {
    var strippingDiacritics: String {
        applyingTransform(.stripDiacritics, reverse: false)!
    }
}
