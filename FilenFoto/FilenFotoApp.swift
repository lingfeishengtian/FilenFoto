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
            
//            SwiftMatchExampleWrapper()
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

#Preview {
    @Previewable @State var showImage = false
    @Previewable @Namespace var namespace
    VStack {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)]) {
            ForEach(0..<10) { i in
                Image("IMG_3284")
                    .resizable()
                    .matchedGeometryEffect(id: "foto\(i)", in: namespace, isSource: true)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .onTapGesture {
                        withAnimation {
                            showImage.toggle()
                        }
                    }
            }
        }
    }
        .overlay {
            if showImage {
                Image("IMG_3284")
                    .resizable()
                    .matchedGeometryEffect(id: "foto\(4)", in: namespace, isSource: false)
                    .scaledToFill()
                    .onTapGesture {
                        withAnimation {
                            showImage.toggle()
                        }
                    }
            }
        }
}
