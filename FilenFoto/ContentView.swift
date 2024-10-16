//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var progress: SyncProgressInfo
    
    init () {
        self.progress = PhotoVisionDatabaseManager.shared.startSync()
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(progress.currentStep)
            Text("\(progress.amountOfImagesSynced)/\(progress.totalAmountOfImages)")
            ProgressView(value: progress.progress)
                .progressViewStyle(.linear)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
