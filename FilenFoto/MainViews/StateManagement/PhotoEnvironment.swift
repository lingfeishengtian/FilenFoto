//
//  PhotoEnvironment.swift
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
//    private var stream: RowIterator?
    @Published var searchArray: [DBPhotoAsset] = []
    private let pollingLimit: Int
    private var isSearching = false
    @Published var searchHistoryCache: [String]
    @Published var shouldShowFullImageView: Bool = false
    @Published var countOfPhotos: Int = 0
    
    init(pollingLimit: Int = 20) {
//        self.stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
        self.pollingLimit = pollingLimit
        self.searchHistoryCache = searchHistory
        
        super.init()
//#if DEBUG
//        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "0") && lazyArray.sortedArray.count < 20_000 {
//            DispatchQueue.main.async {
//                let dbPhoto = self.next()!
//                for i in 0..<20_000 {
//                    self.lazyArray.insert(dbPhoto.setId(String(i), idOffset: Int64(i)))
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
//        Task {
//            lastTask?.cancel()
////            stream = PhotoDatabase.shared.getAllPhotoDatabaseStreamer()
//            await addMoreToLazyArray()
//        }
    }
    
    /// Database always returns values sorted by creation date, which should allow us to poll n amount of times without worrying about things being out of order.
    func searchStream(searchQuery: String) {
        isSearching = true
//        lazyArray.removeAll()
//        Task {
//            lastTask?.cancel()
////            stream = PhotoDatabase.shared.searchForText(textSearch: searchQuery)
//            await addMoreToLazyArray(reset: true)
//        }
    }
}
