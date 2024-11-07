//
//  FilenSyncStatus.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/6/24.
//

import SwiftUI

struct FilenSyncStatus: View {
    @AppStorage("filenImportTasks") var filenImportTasks: String = ""
    @ObservedObject var syncProgress: SyncProgressInfo = SyncProgressInfo()
    @State var filenSyncer: FilenSync?
    
    init() {
//        if filenImportTasks.isEmpty {
//            fatalError("FilenSyncStatus should not be shown when there are no tasks")
//        }
    }

    var body: some View {
        VStack {
            Image(systemName: "arrow.down.circle")
                .symbolEffect(.wiggle.down.byLayer, options: .repeat(.periodic(delay: 2.0)))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.primary, .blue)
                .bold()
                .font(.system(size: 50))
                .padding()
            Text("Importing Photos")
                .font(.title)
                .bold()
                .padding()
            ProgressView(value: syncProgress.progress, total: 1)
                .progressViewStyle(.linear)
                .padding()
                .padding(.horizontal)
            Text("\(syncProgress.getTotalProgress().completedImages)/\(syncProgress.getTotalProgress().totalImages) Photos Imported")
                .font(.title3)
        }.onAppear {
            filenSyncer = FilenSync(folderUUID: filenImportTasks)
            filenSyncer?.startSync(onComplete: {}, onNewDatabasePhotoAdded: { _ in }, progressInfo: syncProgress)
        }
    }
}

//#Preview {
//    FilenSyncStatus()
//}
struct CheckmarkDrawView: View {
    @State private var drawCheckmark = false

    var body: some View {
        VStack {
            CheckmarkShape()
                .trim(from: 0, to: drawCheckmark ? 1 : 0) // Trim from 0 to 1
                .stroke(Color.green, lineWidth: 4) // Stroke properties
                .frame(width: 100, height: 100)
                .animation(.easeOut(duration: 0.8), value: drawCheckmark) // Animate trim
                .onAppear {
                    drawCheckmark = true // Start drawing when it appears
                }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Define points for the checkmark
        let startX = rect.width * 0.2
        let startY = rect.height * 0.5
        let midX = rect.width * 0.4
        let midY = rect.height * 0.7
        let endX = rect.width * 0.8
        let endY = rect.height * 0.3

        // Draw the checkmark shape
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: midX, y: midY))
        path.addLine(to: CGPoint(x: endX, y: endY))

        return path
    }
}

#Preview {
    FilenSyncStatus()
}
