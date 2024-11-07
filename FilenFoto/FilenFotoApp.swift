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
    @AppStorage("filenImportTasks") var filenImportTasks: String = ""
    @AppStorage("compressionLevel") var compressionLevel: CompressionLevels?

    init() {
        if hasPhotoFolder && !isLoggedIn {
            filenPhotoFolderUUID = nil
        }
    }
        
    var body: some Scene {
        WindowGroup {
            /// Ensures no case is missed
            switch (isLoggedIn, hasPhotoFolder, compressionLevel != nil, filenImportTasks.isEmpty) {
            case (true, true, true, true):
                ContentView()
            case (true, true, true, false):
                FilenSyncStatus()
            case (true, true, false, _):
                CompressionLevelSetup()
            case (true, false, _, _):
                SetupFolderRoot(hasPhotoFolder: $hasPhotoFolder)
            case (false, _, _, _):
                Login(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
