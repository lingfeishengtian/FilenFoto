//
//  FFDefaults.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import Foundation

class FFDefaults {
    static let shared = FFDefaults()
    
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    
    private let FILEN_AUTH_DATA_KEY = "filenAuthData"
    private let ROOT_FOLDER_UUID_KEY = "rootFolderUUID"
    private let THUMBNAIL_INDEX_KEY = "thumbnailIndex"
    
    var filenAuthData: Data? {
        get {
            return userDefaults.data(forKey: FILEN_AUTH_DATA_KEY)
        }
        
        set {
            userDefaults.set(newValue, forKey: FILEN_AUTH_DATA_KEY)
        }
    }
    
    var rootFolderUUID: String? {
        get {
            return userDefaults.string(forKey: ROOT_FOLDER_UUID_KEY)
        }
        
        set {
            userDefaults.set(newValue, forKey: ROOT_FOLDER_UUID_KEY)
        }
    }
}
