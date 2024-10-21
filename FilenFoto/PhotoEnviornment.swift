//
//  PhotoEnviornment.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI
import SQLite
import Photos

var searchHistory: [String] {
    get {
        UserDefaults.standard.array(forKey: "searchHistory") as? [String] ?? []
    }
    set {
        var valSet = newValue
        while valSet.count > 4 {
            valSet.removeLast()
        }
        UserDefaults.standard.setValue(valSet, forKey: "searchHistory")
    }
}

class PhotoEnvironment: SyncProgressInfo {
    var firstSelected: DBPhotoAsset? = nil
    @Published var selectedDbPhotoAsset: DBPhotoAsset? = nil
    @Published var scrolledToSelect: DBPhotoAsset? = nil
    private var stream: RowIterator?
    @Published var lazyArray = SortedArray<DBPhotoAsset>()
    private let pollingLimit: Int
    private var isSearching = false
    @Published var searchHistoryCache: [String]
    
    init(pollingLimit: Int = 20) {
        self.stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
        self.pollingLimit = pollingLimit
        self.searchHistoryCache = searchHistory
        
        super.init()
//#if DEBUG
//        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "0") && lazyArray.sortedArray.count < 20000 {
//            DispatchQueue.main.async {
//                let dbPhoto = self.next()!
//                for i in 0..<20000 {
//                    self.lazyArray.insert(dbPhoto.setId(String(i)))
//                }
//                print("Done")
//            }
//        }
//#endif
    }
    
    func addNewSearchHistory(searchQuery: String) {
        if searchHistoryCache.contains(searchQuery) {
            searchHistoryCache.removeAll(where: { $0 == searchQuery })
        }
        searchHistoryCache.insert(searchQuery, at: 0)
        searchHistory = searchHistoryCache
    }
    
    func defaultStream() {
        isSearching = false
        Task {
            for lazyArrayTask in currentLazyArrayTaskQueue {
                lazyArrayTask.cancel()
            }
            currentLazyArrayTaskQueue.removeAll()
            stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
            await addMoreToLazyArray()
        }
    }
    
    /// Database always returns values sorted by creation date, which should allow us to poll n amount of times without worrying about things being out of order.
    func searchStream(searchQuery: String) {
        isSearching = true
//        lazyArray.removeAll()
        Task {
            for lazyArrayTask in currentLazyArrayTaskQueue {
                lazyArrayTask.cancel()
            }
            currentLazyArrayTaskQueue.removeAll()
            stream = PhotoDatabase.shared.searchForText(textSearch: searchQuery)
            await addMoreToLazyArray(reset: true)
        }
    }
    
    private var currentLazyArrayTaskQueue: [Task<Void, Never>] = []
    func addMoreToLazyArray(reset: Bool = false) async {
        if currentLazyArrayTaskQueue.count > 2 {
            for task in currentLazyArrayTaskQueue {
                task.cancel()
            }
            currentLazyArrayTaskQueue.removeAll()
        }
        currentLazyArrayTaskQueue.append(Task {
            print("Call to add", PhotoDatabase.shared.getCountOfPhotos(), lazyArray.sortedArray.count)
            var pollLimit = pollingLimit
            var toInsert: [DBPhotoAsset] = []
            while pollLimit > 0 {
                if let asset = next() {
                    if (self.lazyArray.doesExist(asset) && !reset) || toInsert.firstIndex(of: asset) != nil {
                    } else {
                        toInsert.append(asset)
                        pollLimit -= 1
                    }
                } else if (PhotoDatabase.shared.getCountOfPhotos() > (lazyArray.sortedArray.count + toInsert.count) && !isSearching) {
                    self.stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
                } else {
                    break
                }
            }
            DispatchQueue.main.async { [toInsert] in
                self.lazyArray.insertAll(toInsert, resetting: reset)
            }
        })
    }
    
    func next() -> DBPhotoAsset? {
        do {
            if let n = try stream?.failableNext() {
                let nLat = try n.get(locationLatitudeColumn)
                let nLon = try n.get(locationLongitudeColumn)
                var loc: CLLocation? = nil
                if nLat != nil && nLon != nil {
                    loc = CLLocation(latitude: nLat!, longitude: nLon!)
                }
                
                return DBPhotoAsset(
                    id: try n.get(idColumn),
                    localIdentifier: try n.get(assetColumn),
                    mediaType: PHAssetMediaType(rawValue: Int(try n.get(mediaTypeColumn))) ?? .image,
                    mediaSubtype: PHAssetMediaSubtype(rawValue: UInt(try n.get(mediaSubtypeColumn))),
                    creationDate: try n.get(creationDateColumn),
                    modificationDate: try n.get(modificationDateColumn),
                    location: loc,
                    favorited: try n.get(favorited),
                    hidden: try n.get(hidden),
                    thumbnailFileName: try n.get(thumbnailName)
//                    thumbnailCacheName: try n.get(thumbnailCacheName)
                )
            } else {
                return nil
            }
        } catch {
            print(error)
            return nil
        }
    }
}
