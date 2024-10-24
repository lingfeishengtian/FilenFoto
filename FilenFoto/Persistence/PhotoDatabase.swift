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

struct DBPhotoAsset : Comparable, Hashable {
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
    func setId(_ idLocalID: String) -> DBPhotoAsset {
        return DBPhotoAsset(id: id, localIdentifier: idLocalID, mediaType: mediaType, mediaSubtype: mediaSubtype, creationDate: Date.now - 9999999999999 - TimeInterval(Int(idLocalID) ?? 0), modificationDate: modificationDate, location: location, favorited: favorited, hidden: hidden, thumbnailFileName: thumbnailFileName)
    }
#endif
    
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
//    let thumbnailCacheName: String?
}


// Bug in SQLite right now
typealias Expression = SQLite.Expression
let photoAssetTable = Table("photoAsset")
let idColumn = Expression<Int64>("id")
let assetColumn = Expression<String>("localIdentifier")
let mediaTypeColumn = Expression<Int64>("mediaType")
let mediaSubtypeColumn = Expression<Int64>("mediaSubtype")
let creationDateColumn = Expression<Date>("creationDate")
let modificationDateColumn = Expression<Date>("modificationDate")
let locationLongitudeColumn = Expression<Double?>("locationLongitude")
let locationLatitudeColumn = Expression<Double?>("locationLatitude")
let hashColumn = Expression<String>("hash")
let completedAnalysis = Expression<Bool>("completedAnalysis")
let favorited = Expression<Bool>("favorited")
let hidden = Expression<Bool>("hidden")
let thumbnailName = Expression<String>("thumbnailLocation")
let thumbnailCacheName = Expression<String?>("thumbnailCacheName")

let photoResourcesTable = Table("photoResources")
let uuidColumn = Expression<String>("uuid")
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

struct SortedArray<T: Comparable> {
    private var array: Array<T> = []

    // Access to the sorted array
    var sortedArray: [T] {
        return array
    }
    
    mutating func removeAll() {
        array.removeAll()
    }
    
    func binSearch(_ element: T) -> Int {
        return array.binarySearch(predicate: { $0 > element})
    }
    
    func doesExist(_ element: T) -> Bool {
        let binSearchedResult = array.binarySearch(predicate: { $0 > element})
        if array.count > 0 && binSearchedResult < array.count && array[binSearchedResult] == element {
            return true
        }
        return false
    }
    
    mutating func insertAll(_ elements: [T], resetting: Bool = false) {
        var tmpArr = resetting ? [] : array
        
        func insertIntoArr(_ element: T, _ arr: inout [T]) {
            let binSearchedResult = arr.binarySearch(predicate: { $0 > element})
            if arr.count > 0 && binSearchedResult < arr.count && arr[binSearchedResult] == element {
                return
            }
            
            arr.insert(element, at: binSearchedResult)
        }
        
        for element in elements {
            insertIntoArr(element, &tmpArr)
        }
        
        array = tmpArr
    }

    // O(lg n)
    // Insert new element and keep array sorted
    mutating func insert(_ element: T) {
        let binSearchedResult = array.binarySearch(predicate: { $0 > element})
        if array.count > 0 && binSearchedResult < array.count && array[binSearchedResult] == element {
            return
        }
        
//#if DEBUG
//        if binSearchedResult != array.count {
//            fatalError("Not supposed to insert in between")
//        }
//#endif
        
//#if DEBUG
//        if array.contains(where: { ($0 as! DBPhotoAsset).localIdentifier == (element as! DBPhotoAsset).localIdentifier}) {
//            fatalError("SHOULD NOT HAVE EQUALS")
//        }
//#endif
        
//        let index = array.firstIndex { $0 < element } ?? array.count
//        if binSearchedResult != index {
//            fatalError("binsearch diff")
//        }
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

//class PhotoDatabaseStreamer: ObservableObject {
//    private var stream: RowIterator?
//    @Published var lazyArray = SortedArray<DBPhotoAsset>()
//    private let pollingLimit: Int
//    private var isSearching = false
//    
//    internal init(pollingLimit: Int = 10) {
//        self.stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
//        self.pollingLimit = pollingLimit
//    }
//    
//    func defaultStream() {
//        isSearching = false
//        stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
//        addMoreToLazyArray()
//    }
//    
//    func searchStream(searchQuery: String) {
//        isSearching = true
//        lazyArray.removeAll()
//        stream = PhotoDatabase.shared.searchForText(textSearch: searchQuery)
//        addMoreToLazyArray()
//    }
//    
//    func addMoreToLazyArray() {
//        print(PhotoDatabase.shared.getCountOfPhotos(), lazyArray.sortedArray.count)
//        var pollLimit = pollingLimit
//        while pollLimit > 0 {
//            if let asset = next() {
//                self.lazyArray.insert(asset)
//                pollLimit -= 1
//            } else if (PhotoDatabase.shared.getCountOfPhotos() > lazyArray.sortedArray.count && !isSearching) {
//                self.stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
//                if let assetTryAgain = next() {
//                    self.lazyArray.insert(assetTryAgain)
//                    pollLimit -= 1
//                }
//            } else {
//                break
//            }
//        }
//    }
//    
//    func next() -> DBPhotoAsset? {
//        do {
//            if let n = try stream?.failableNext() {
//                let nLat = try n.get(locationLatitudeColumn)
//                let nLon = try n.get(locationLongitudeColumn)
//                var loc: CLLocation? = nil
//                if nLat != nil && nLon != nil {
//                    loc = CLLocation(latitude: nLat!, longitude: nLon!)
//                }
//                
//                return DBPhotoAsset(
//                    id: try n.get(idColumn),
//                    localIdentifier: try n.get(assetColumn),
//                    mediaType: PHAssetMediaType(rawValue: Int(try n.get(mediaTypeColumn))) ?? .image,
//                    mediaSubtype: PHAssetMediaSubtype(rawValue: UInt(try n.get(mediaSubtypeColumn))),
//                    creationDate: try n.get(creationDateColumn),
//                    modificationDate: try n.get(modificationDateColumn),
//                    location: loc,
//                    favorited: try n.get(favorited),
//                    hidden: try n.get(hidden),
//                    thumbnailFileName: try n.get(thumbnailName)
////                    thumbnailCacheName: try n.get(thumbnailCacheName)
//                )
//            } else {
//                return nil
//            }
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//}

class PhotoDatabase {
    static let shared = PhotoDatabase()
    private static let databaseName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotoDatabase.db", conformingTo: .database)
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
            t.column(favorited)
            t.column(hidden)
            t.column(thumbnailName)
//            t.column(thumbnailCacheName)
            t.column(completedAnalysis, defaultValue: false)
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
    
    // Check for completedAnalysis, if photo's completed analysis is false, remove all instances of it from the database
    func doesPhotoExist(_ asset: PHAsset) -> Bool {
        let query = photoAssetTable.filter(assetColumn == asset.localIdentifier)
        let result = try? databaseConnection?.prepare(query)
        if let result = result {
            for row in result {
                if row[completedAnalysis] {
                    return true
                } else {
                    // delete cascade
                    let _ = try? databaseConnection?.run(photoResourcesTable.filter(assetIdColumn == row[idColumn]).delete())
                    let _ = try? databaseConnection?.run(identifiedObjectsTable.filter(assetIdColumn == row[idColumn]).delete())
                    let _ = try? databaseConnection?.run(recognizedTextTable.filter(assetIdColumn == row[idColumn]).delete())
                    let _ = try? databaseConnection?.run(photoAssetTable.filter(assetColumn == asset.localIdentifier).delete())
                    return false
                }
            }
        }
        return false
    }
    
    func getCountOfPhotos() -> Int {
        let query = photoAssetTable.count
        let result = try? databaseConnection?.scalar(query)
        return result ?? 0
    }
    
    func getAllPhotoDatabaseStreamer() -> RowIterator? {
        let query = photoAssetTable.select(*).order(creationDateColumn.desc)
        let stream = try? databaseConnection?.prepareRowIterator(query)
        return stream
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
            let streamScalar = try databaseConnection?.scalar(sql, [textSearch, textSearch])
            print("\(streamScalar) results found for search \(textSearch)")
            let stream = try databaseConnection?.prepareRowIterator(sql, bindings: [textSearch, textSearch])
            return stream
        } catch {
            logger.error("Failed search \(error)")
        }
        return nil
    }
    
    func insertPhoto(asset: PHAsset, resources: [FilenEquivelentAsset], imageClassificationResults: [VNClassificationObservation], textResultClassificationResults: [VNRecognizedTextObservation], thumbnailLocation: URL) -> InsertPhotoResult {
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
                                            thumbnailName <- thumbnailLocation.lastPathComponent)
        
        let id = try? databaseConnection?.run(insert)
        if let id = id {
            self.logger.info("Inserted photo with ID \(id)")
            
            var insertedImageClassificationCount = 0
            var insertedTextResultClassificationCount = 0
            var insertedResourceCount = 0
            
//            var thumbnailCacheFileName: String? = nil
                        
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
//                    if thumbnailCacheFileName == nil {
//                        let ogFilename = resource.phAssetResource.originalFilename
//                        thumbnailCacheFileName = String(id) + "." + String(ogFilename.suffix(from: ogFilename.index(ogFilename.lastIndex(of: ".") ?? ogFilename.endIndex, offsetBy: 1)))
//                    }
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
            let update = query.update(completedAnalysis <- true)
            let _ = try? databaseConnection?.run(update)

            return .success
        }
        return .failed
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
    
    struct DBPhotoResourceResult {
        let id: Int64
        let assetId: Int64
        let uuid: String
        let resourceType: PHAssetResourceType
        let sha256: String
        let resourceExtension: String
    }
    
    enum InsertPhotoResult {
        case success
        case exists
        case failed
    }
}
