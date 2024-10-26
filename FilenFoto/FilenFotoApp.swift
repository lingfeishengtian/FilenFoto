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
    @AppStorage("compressionLevel") var compressionLevel: CompressionLevels?

    init() {
        if hasPhotoFolder && !isLoggedIn {
            filenPhotoFolderUUID = nil
        }
    }
        
    var body: some Scene {
        WindowGroup {
            if isLoggedIn && hasPhotoFolder && compressionLevel != nil {
                ContentView()
            } else if isLoggedIn {
                if !hasPhotoFolder {
                    SetupFolderRoot(hasPhotoFolder: $hasPhotoFolder)
                } else if compressionLevel == nil {
                    CompressionLevelSetup()
                }
            } else {
                Login(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
