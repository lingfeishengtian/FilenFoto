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
    @Published var scrolledToSelect: DBPhotoAsset? = nil
//    private var stream: RowIterator?
    @Published var searchArray: [DBPhotoAsset] = []
    private let pollingLimit: Int
    private var isSearching = false
    @Published var searchHistoryCache: [String]
    @Published var shouldShowFullImageView: Bool = false
    @Published var countOfPhotos: Int = 0
    @Published private var pairedSelectedDbPhotoAsset: DBPhotoAsset? = nil
    private var selectedDBPhotoAssetIndex: Int = 0
    private var photoInsertQueue = [IndexPath]()
    @Published private var storedBaseFolderUUID: String? = nil
    
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
        self.countOfPhotos = PhotoDatabase.shared.getCountOfPhotos()
        
    }
    
    
    var baseFolderUUID: String? {
        if storedBaseFolderUUID == nil {
            Task {
                let uuid = try? await getFilenClientWithUserDefaultConfig()?.baseFolder().uuid
                DispatchQueue.main.async {
                    self.storedBaseFolderUUID = uuid
                }
            }
        }
        
        return storedBaseFolderUUID
    }
    
    var selectedDbPhotoAsset : DBPhotoAsset? {
        pairedSelectedDbPhotoAsset
    }
    
    func eventPhotoInserted(_ dbPhotoAsset: DBPhotoAsset) {
        guard let selectedDbPhotoAsset else {
            countOfPhotos += 1
            return
        }
        
        if dbPhotoAsset.creationDate > selectedDbPhotoAsset.creationDate {
            selectedDBPhotoAssetIndex += 1
        } else if dbPhotoAsset.creationDate < selectedDbPhotoAsset.creationDate {
            selectedDBPhotoAssetIndex += 0 // index doesnt change if value was appended
        } else {
            if dbPhotoAsset.id > selectedDbPhotoAsset.id {
                selectedDBPhotoAssetIndex += 1
            } else {
                selectedDBPhotoAssetIndex += 0 // index doesnt change if value was appended
            }
        }
        
        countOfPhotos += 1
        photoInsertQueue.append(IndexPath(item: PhotoDatabase.shared.index(of: dbPhotoAsset), section: 0))
#if DEBUG
        assert(PhotoDatabase.shared.getCountOfPhotos() == countOfPhotos)
#endif
    }
    
    func retrieveAndClearPhotoInsertQueue() -> [IndexPath] {
        let queue = photoInsertQueue
        photoInsertQueue.removeAll()
        return queue
    }
    
    func setCurrentSelectedDbPhotoAsset(_ dbPhotoAsset: DBPhotoAsset, index: Int, animate: Bool = true) {
        DispatchQueue.main.async {
            if animate {
                withAnimation {
                    self.selectedDBPhotoAssetIndex = index
                    self.pairedSelectedDbPhotoAsset = dbPhotoAsset
                    self.shouldShowFullImageView = true
                }
            } else {
                self.selectedDBPhotoAssetIndex = index
                self.pairedSelectedDbPhotoAsset = dbPhotoAsset
                self.shouldShowFullImageView = true
            }
        }
    }
    
//    func () {
//        DispatchQueue.main.async {
//            withAnimation {
//                
//            }
//        }
//    }
    
    func getCurrentPhotoAssetIndex() -> Int? {
        guard selectedDbPhotoAsset != nil else {
            return nil
        }
        
        return selectedDBPhotoAssetIndex
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
