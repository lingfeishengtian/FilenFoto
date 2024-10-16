//
//  FilenFotoApp.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI

@main
struct FilenFotoApp: App {
    @State var isLoggedIn: Bool = FilenFoto.isLoggedIn()
    @State var hasPhotoFolder: Bool = filenPhotoFolderUUID != nil
    
    init() {
        if hasPhotoFolder && !isLoggedIn {
            filenPhotoFolderUUID = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
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
