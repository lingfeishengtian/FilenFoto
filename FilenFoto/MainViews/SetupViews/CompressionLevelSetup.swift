//
//  CompressionLevelSetup.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/25/24.
//

import SwiftUI

/*
 None: DO NOT RECOMMEND can be bigger than original file size
 */

struct CompressionLevelSetup : View {
    @AppStorage("compressionLevel") var compressionLevelAppStorage: CompressionLevels = .high
    @State private var compressionLevel: CompressionLevels = .high
    @State private var pulsingScale: CGFloat = 1.1
    
    func estimateSizeThumbnails() -> String {
        let numPhotos = PhotoVisionDatabaseManager.shared.getTotalNumberOfPhotos()
        var totSize = 0
        switch compressionLevel {
        case .none:
            totSize = numPhotos * 500_000
        case .low:
            totSize = numPhotos * 200_000
        case .medium:
            totSize = numPhotos * 100_000
        case .high:
            totSize = numPhotos * 50_000
        case .extreme:
            totSize = numPhotos * 10_000
        }
        return StorageSizeLookup.formatStringSize(totSize)
    }
    
    var body: some View {
        NavigationStack {
            PushAnimationView()
            Text("Thumbnail Image Compression")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding()
            Text("To conserve storage, please choose an appropriate compression level.")
                .font(.headline)
                .multilineTextAlignment(.center)
            VStack {
                HStack {
                    Text("~10 KB / image (low quality)")
                        .bold()
                    Spacer()
                    Button("Extreme") {
                        withAnimation {
                            compressionLevel = .extreme
                        }
                    }.buttonStyle(.borderedProminent)
                        .tint(compressionLevel == .extreme ? .green : .blue)
                    
                }
                HStack {
                    Text("~50 KB / image")
                        .bold()
                    Spacer()
                    Button("High") {
                            withAnimation {
                                compressionLevel = .high
                            }
                    }.buttonStyle(.borderedProminent)
                        .tint(compressionLevel == .high ? .green : .blue)
                        .scaleEffect(pulsingScale)
                        .animation(.easeIn(duration: 0.4).repeatForever(), value: pulsingScale)
                }
                HStack {
                    Text("~100 KB / image")
                        .bold()
                    Spacer()
                    Button("Medium") {
                        withAnimation {
                            compressionLevel = .medium
                        }
                    }.buttonStyle(.borderedProminent)
                        .tint(compressionLevel == .medium ? .orange : .blue)
                }
                
                HStack {
                    Text("~200 KB / image")
                        .bold()
                    Spacer()
                    Button("Low") {
                        withAnimation {
                            compressionLevel = .low
                        }
                    }.buttonStyle(.borderedProminent)
                        .tint(compressionLevel == .low ? .orange : .blue)
                }
                
                HStack {
                    Text(">300 KB / image")
                        .bold()
                    Spacer()
                    Button("None") {
                        withAnimation {
                            compressionLevel = CompressionLevels.none
                        }
                    }.buttonStyle(.borderedProminent)
                        .tint(compressionLevel == .none ? .orange : .blue)
                }
            }
            .padding()
            .padding(.horizontal)
            
            Text("You have \(PhotoVisionDatabaseManager.shared.getTotalNumberOfPhotos()) photos. \(compressionLevel.rawValue) compression will result in \(estimateSizeThumbnails()) of storage.")
                .bold()
                .multilineTextAlignment(.center)
                .padding()
            
            Button {
                compressionLevelAppStorage = compressionLevel
            } label: {
                Text("Submit")
            }.buttonStyle(.borderedProminent)
        }.onAppear {
            pulsingScale = 1.0
        }
    }
}

#Preview {
    CompressionLevelSetup()
}

struct PushAnimationView: View {
    @State private var isCompressed = false
    @State private var arrowOffset: CGFloat = -20
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrow.down")
                .offset(y: -arrowOffset)
                .bold()
                .animation(
                    Animation.linear(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: arrowOffset
                )
            
            // Compressible Rectangle
            Rectangle()
                .fill(Color.clear)
                .overlay( /// apply a rounded border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.blue, lineWidth: 5)
                )
                .frame(width: 100, height: 25)
                .scaleEffect(y: isCompressed ? 1.0 : 0.8, anchor: .center)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isCompressed
                )
                .onAppear {
                    isCompressed.toggle()
                }
                .padding(30)
            
            Image(systemName: "arrow.up")
                .offset(y: arrowOffset)
                .bold()
                .animation(
                    Animation.linear(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: arrowOffset
                )
        }
        .onAppear {
            arrowOffset = 0
        }
    }
}
