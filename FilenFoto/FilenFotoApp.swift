//
//  FilenFotoApp.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import CoreLocation

@main
struct FilenFotoApp: App {
    @State var isLoggedIn: Bool = FilenFoto.isLoggedIn()
    @State var hasPhotoFolder: Bool = filenPhotoFolderUUID != nil
    
    init() {
        if hasPhotoFolder && !isLoggedIn {
            filenPhotoFolderUUID = nil
        }
    }
    
    let photoEnvironment: PhotoEnvironment = PhotoEnvironment()
    
    var body: some Scene {
        WindowGroup {
//            for i in 0..<20000 {
//                let dbPhotoAsset: DBPhotoAsset = .init(
//                    id: -1, localIdentifier: String(i), mediaType: .image, mediaSubtype: .photoHDR,
//                    creationDate: Date.now - 1_000_000, modificationDate: Date.now,
//                    location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
//                    thumbnailFileName: "meow.jpg")
//                photoEnvironment.lazyArray.insert(
//                    dbPhotoAsset
//                )
//            }

//            photoEnvironment.selectedDbPhotoAsset = photoEnvironment.lazyArray.sortedArray.last!
//            return VStack {
//                Text("Hello")
//                PhotoScrubberView(itemsToShow: 10, spacing: 10)
//                    .environmentObject(photoEnvironment)
//            }
            if isLoggedIn && hasPhotoFolder {
                ContentView()
            } else if isLoggedIn {
                SetupFolderRoot(hasPhotoFolder: $hasPhotoFolder)
            } else {
                Login(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
