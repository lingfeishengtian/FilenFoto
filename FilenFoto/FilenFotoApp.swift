//
//  FilenFotoApp.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import SwiftUI

@main
struct FilenFotoApp: App {
    @StateObject var photoContext = PhotoContext()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoContext)
                .environment(\.managedObjectContext, FFCoreDataManager.shared.mainThreadManagedContext)
                .onChange(of: scenePhase) { newPhase, oldPhase in
                    switch newPhase {
                    case .background:
                        FFCoreDataManager.shared.saveContextIfNeeded()
                    default:
                        break
                    }
                }
        }
    }
}
