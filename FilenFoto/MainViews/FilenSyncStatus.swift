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
    @State var finishSyncing: Bool = false
    @State var showWarning: Bool = false
    @State var showCompleted: Bool = false
    
    @Namespace var animation
    
    init() {
        //        if filenImportTasks.isEmpty {
        //            fatalError("FilenSyncStatus should not be shown when there are no tasks")
        //        }
    }
    
    var body: some View {
        VStack {
            if showCompleted {
                CheckmarkDrawView()
                Text("Completed Import")
                    .font(.title)
                    .bold()
                    .padding()
                VStack {
                    Text("Additional Cleanup Options")
                        .font(.headline)
                        .bold()
                    Button {
                    } label: {
                        Label("Delete Imported Photos from Filen", systemImage: "trash")
                    }.buttonStyle(.borderedProminent)
                    Button {
                    } label: {
                        Label("Clean Cached Sync History", systemImage: "eraser.fill")
                    }.buttonStyle(.borderedProminent)
                        .tint(.red)
                    Button {
                        // TODO: Warn user that this will cause all photos to re-import
                    } label: {
                        Label("Refresh Import Queue", systemImage: "arrow.clockwise")
                    }.buttonStyle(.borderedProminent)
                    Text("Compares imported photos with Filen and determines new files to import.")
                        .bold()
                        .padding(.horizontal)
                        .multilineTextAlignment(.leading)
                    Button {
                        withAnimation {
                            filenImportTasks = ""
                        }
                    } label: {
                        Text("Continue to Photos")
                    }.buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .padding()
                }.transition(
                    .move(edge: .bottom)
                    .animation(.bouncy.delay(10.0))
                ).padding()
                
            } else if finishSyncing {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolEffect(.bounce, options: .repeat(.periodic(3, delay: 0.2)))
                        .symbolRenderingMode(.multicolor)
                        .bold()
                        .font(.system(size: 50))
                        .padding()
                    Text("Failed Imports")
                        .font(.title)
                        .bold()
                    Button {
                        withAnimation {
                            showCompleted.toggle()
                        }
                    } label: {
                        Label("Continue", systemImage: "arrow.right")
                    }.buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .padding([.bottom])
                    ScrollView {
                        LazyVStack {
                            ForEach(filenSyncer?.failedImports ?? [], id: \.fileUUID) { failedImport in
                                FailedImportView(failedImport: failedImport)
                                    .onAppear {
                                        if failedImport.fileUUID == filenSyncer?.failedImports.last?.fileUUID {
                                            filenSyncer?.addMoreFailedImportsFromStream()
                                        }
                                    }
                            }
                            Color.clear.frame(height: 50)
                        }
                    }
                }.overlay {
                    VStack {
                        Spacer()
                        HStack {
                            Button {
                                withAnimation {
                                    showWarning.toggle()
                                }
                            } label: {
                                Label("Share Debug Info", systemImage: "square.and.arrow.up")
                            }.buttonStyle(.borderedProminent)
                                .buttonBorderShape(.capsule)
                        }
                    }
                }
                .sheet(isPresented: $showWarning) {
                    if let dbFilePath = filenSyncer?.dbFilePath {
                        VStack {
                            Label("Notice", systemImage: "exclamationmark.bubble.fill")
                                .font(.largeTitle)
                                .bold()
                                .symbolRenderingMode(.hierarchical)
                                .padding()
                            Text("Debug information may include unencrypted information about file names. Your images will not be exported.")
                                .padding(.horizontal)
                            ShareLink("Share Debug Info", item: dbFilePath, subject: Text("DebugDatabase"), message: Text("Sync database debug information"))
                                .padding()
                        }.presentationDetents([.height(250)])
                    }
                }
            } else {
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
            }
        }.onAppear {
            filenSyncer = FilenSync(folderUUID: filenImportTasks)
            filenSyncer?.startSync(onComplete: {
                withAnimation {
                    if !(filenSyncer?.failedImports.isEmpty ?? false) {
                        finishSyncing = true
                    } else {
                        showCompleted = true
                    }
                }
            }, onNewDatabasePhotoAdded: { _ in }, progressInfo: syncProgress)
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

struct FailedImportView: View {
    let failedImport: FailedStatus
    @State var showMoreInfo: Bool = false
    
    var body: some View {
        HStack {
            Text(failedImport.fileName ?? failedImport.fileUUID)
                .bold()
            Spacer()
            //            Text(failedImport.statusMessage)
            //                .lineLimit(1)
            Button {
                showMoreInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .popover(isPresented: $showMoreInfo, attachmentAnchor: .point(.top), arrowEdge: .top) {
                Text(failedImport.statusMessage)
                    .padding()
                    .popoverMultilineHeightFix()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 2)
    }
}

#Preview {
    FilenSyncStatus()
}

private struct PopoverMultilineHeightFix: ViewModifier {
    @State var textHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .overlay(
                GeometryReader { proxy in
                    Color
                        .clear
                        .preference(key: ContentLengthPreference.self,
                                    value: proxy.size.height)
                }
            )
            .onPreferenceChange(ContentLengthPreference.self) { value in
                DispatchQueue.main.async {
                    self.textHeight = value
                }
            }
            .frame(height: self.textHeight)
    }
}

private extension PopoverMultilineHeightFix {
    struct ContentLengthPreference: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

extension View {
    func popoverMultilineHeightFix() -> some View {
        modifier(PopoverMultilineHeightFix())
    }
}
