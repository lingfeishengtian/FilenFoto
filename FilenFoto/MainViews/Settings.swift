//
//  Settings.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/25/24.
//

import SwiftUI
import Charts

enum FilenFotoStorageComponent: String, RawRepresentable, CaseIterable, Identifiable, Plottable {
    case cacheDirectory = "Cache"
    case thumbnailDirectory = "Thumbnails"
    case databaseFile = "Database File"
    
    var id: Int { rawValue.hashValue }
}

enum CacheSizeValues: Int, CaseIterable, Identifiable {
    case 十MB = 10
    case 一百MB = 100
    case 五百MB = 500
    case 一GB = 1_000
    case 五GB = 5_000
    case 十GB = 10_000
    case 十五GB = 15_000
    case 二十GB = 20_000
    case 三十GB = 30_000
    case 五十GB = 50_000
    case 一百GB = 100_000
    case 两百GB = 200_000
    case 五百GB = 500_000
    case 一TB = 1_000_000
    case 无限 = -1
    
    var id: Int { rawValue }
}

class StorageSizeLookup: ObservableObject {
    @Published var totalSize: Int = -1
    private var categorySizes: [FilenFotoStorageComponent: Int] = [:]
    
    func startSizeCalculations() async {
        for category in FilenFotoStorageComponent.allCases {
            categorySizes[category] = getSizeOf(directory: category)
        }
        
        DispatchQueue.main.async {
            withAnimation {
                self.totalSize = self.categorySizes.values.reduce(0, +)
            }
        }
    }
    
    func reset() {
        categorySizes.removeAll()
        totalSize = -1
    }
    
    func getSizePercentFor(category: FilenFotoStorageComponent) -> Double {
        Double(categorySizes[category] ?? 0) / Double(totalSize)
    }
    
    func sizeStringFormatted(for category: FilenFotoStorageComponent) -> String {
        let size = categorySizes[category] ?? 0
        return StorageSizeLookup.formatStringSize(size)
    }
    
    static func formatStringSize(_ size: Int) -> String {
        if size < 0 {
            return "Unlimited"
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func getSizeOf(directory: FilenFotoStorageComponent) -> Int {
#if DEBUG
        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"],
           isPrev == "1" {
            switch directory {
            case .cacheDirectory:
                return 1000
            case .thumbnailDirectory:
                return 500
            case .databaseFile:
                return 200
            }
        }
#endif
        
        var directoryUrl: URL
        
        switch directory {
        case .cacheDirectory:
            directoryUrl = FullSizeImageCache.cacheDirectory
        case .thumbnailDirectory:
            directoryUrl = PhotoVisionDatabaseManager.shared.thumbnailsDirectory
        case .databaseFile:
            directoryUrl = PhotoDatabase.databaseName
        }
        
        let fileManager = FileManager.default
        var totalSize: Int = 0
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil)
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                totalSize += attributes[FileAttributeKey.size] as! Int
            }
        } catch {
            print("Error: \(error)")
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: directoryUrl.path)
                return attributes[FileAttributeKey.size] as! Int
            } catch {
                print("Error not a file: \(error)")
            }
        }
        
        return totalSize
    }
}

struct Settings: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @AppStorage("maxCacheSize") var maxCacheSize: CacheSizeValues = .一GB // mb
    @AppStorage("regenerateThumbnails") var regenerateThumbnails: Bool = false
    @AppStorage("compressionLevel") var compressionLevel: CompressionLevels = .high
    // TODO: Support multiple import tasks
    @AppStorage("filenImportTasks") var filenImportTasks: String = ""
    @StateObject var filenFotoStorage: StorageSizeLookup = StorageSizeLookup()
    
    func iIndex(for component: FilenFotoStorageComponent) -> Int {
        FilenFotoStorageComponent.allCases.firstIndex(of: component) ?? 0
    }
    
    let colorList: [Color] = [.blue, .green, .orange]
    
    @State var cacheSizeString: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if filenFotoStorage.totalSize > 0 {
                        Chart {
                            ForEach(FilenFotoStorageComponent.allCases, id: \.id) { component in
                                BarMark(
                                    x: .value("X", filenFotoStorage.getSizePercentFor(category: component))
                                )
                                .foregroundStyle(colorList[iIndex(for: component)])
                                .clipShape(clipShape(forIndex: iIndex(for: component)))
                                .foregroundStyle(by: .value("X", component))
                                if iIndex(for: component) != FilenFotoStorageComponent.allCases.count - iIndex(for: component) {
                                    BarMark(x: .value("Separator", 0.01))
                                        .foregroundStyle(.clear)
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 0))
                        }
                        .frame(height: 50)
                        .padding()
                        VStack {
                            ForEach(FilenFotoStorageComponent.allCases, id: \.id) { component in
                                HStack {
                                    Text(component.rawValue)
                                    Spacer()
                                    Text(filenFotoStorage.sizeStringFormatted(for: component))
                                }
                            }
                        }
                        Picker("Max Cache Size", selection: $maxCacheSize) {
                            ForEach(CacheSizeValues.allCases) { cacheSize in
                                Text(StorageSizeLookup.formatStringSize(cacheSize.rawValue * 1_000 * 1_000)).tag(cacheSize)
                            }
                        }.onChange(of: maxCacheSize) {
                            FullSizeImageCache.deleteOldestFilesInCache(untilFolderSizeIsUnder: FullSizeImageCache.shared.maxCacheSize.rawValue)
                            filenFotoStorage.reset()
                            Task {
                                await filenFotoStorage.startSizeCalculations()
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    }
                } header: {
                    Text("Storage Management")
                } footer: {
                    Text("WARNING: ")
                        .foregroundStyle(.red) +
                    Text("After selecting a new cache size, the app will attempt to resize the folder by deleting cached images until it is under the new size.")
                }
                
                // TODO: Image compression settings
                Section {
                    Picker("Thumbnail Compression", selection: $compressionLevel) {
                        ForEach(CompressionLevels.allCases) { compressionLevel in
                            Text(compressionLevel.rawValue).tag(compressionLevel)
                        }
                    }
//                    Toggle(isOn: $regenerateThumbnails) {
//                        Text("Regenerate Thumbnails")
//                    }
                } header: {
                    Text("Thumbnails")
                } footer: {
                    Text("Changing compression quality will not affect existing thumbnails.")
                }
                
                Section("Filen Account Management") {
                    HStack {
                        NavigationLink {
                            if let baseFolderUUID = photoEnvironment.baseFolderUUID {
                                SetupFolder(currentFolderUuid: baseFolderUUID, onSelected: { uuid in
                                    filenImportTasks = uuid
                                }, requiresEmptyFolder: false)
                            }
                        } label: {
                            Text("Import Images")
                        }
                    }
                    Button {
                        
                    } label: {
                        Text("Backup Database")
                    }
                }
            }.navigationTitle("Settings")
        }.onAppear {
            Task {
                await filenFotoStorage.startSizeCalculations()
            }
        }
    }
    
    func clipShape(forIndex i: Int) -> UnevenRoundedRectangle {
        if i == 0 {
            return UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 5)
        } else if i == FilenFotoStorageComponent.allCases.count - 1 {
            return UnevenRoundedRectangle(bottomTrailingRadius: 5, topTrailingRadius: 5)
        } else {
            return UnevenRoundedRectangle()
        }
    }
}

#Preview {
    @Previewable @State var cacheSizeString: String = ""

    Settings()
}
