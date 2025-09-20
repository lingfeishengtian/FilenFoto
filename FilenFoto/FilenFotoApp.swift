//
//  FilenFotoApp.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import SwiftUI



@main
struct FilenFotoApp: App {
    @StateObject var photoContext = PhotoContext.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoContext)
                .environment(\.managedObjectContext, FFCoreDataManager.shared.mainContext)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .background:
                        Task { @MainActor in
                            await FFCoreDataManager.shared.saveContextIfNeeded()
                        }
                    default:
                        break
                    }
                }
        }
    }
}
