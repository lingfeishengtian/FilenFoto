//
//  FilenFotoApp.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import CoreLocation

import SwiftUIPager

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

//struct FilenFotoApp_Previews: PreviewProvider {
//    @State static var selected: Int? = nil
//    static let arr = Array(0...50)
//    @Namespace static var photo
//    
//    static var previews: some View {
//        if selected != nil {
//            let _ = print("Selected: \(selected!)")
//            Image("IMG_3284")
//                .resizable()
//                .matchedGeometryEffect(id: selected!, in: photo)
//                .scaledToFit()
//                .onTapGesture {
//                    selected = nil
//                }
//        } else {
//            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
//                ForEach(arr, id: \.self) { id in
//                    Image("IMG_3284")
//                        .resizable()
//                        .matchedGeometryEffect(id: id, in: photo)
//                        .scaledToFit()
//                        .onTapGesture {
//                            print(id)
//                            selected = id
//                        }
//                }
//            }
//        }
//    }
//}

#Preview {
    @Previewable @State var selected: Int? = nil
    @Previewable var arr = Array(0...50)
    @Previewable @Namespace var photo
    
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
        ForEach(arr, id: \.self) { id in
            Image("IMG_3284")
                .resizable()
                .matchedGeometryEffect(id: id, in: photo)
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .aspectRatio(1, contentMode: .fit)
                .zIndex(selected == id ? 1 : 0)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 2)) {
                        selected = id
                    }
                }
        }
    }
    .overlay {
        if selected != nil {
//            Color.clear.background(
//                Image("IMG_3284")
//                .resizable()
//                .matchedGeometryEffect(
//                    id: selected!,
//                    in: photo,
//                    properties: .position
//                )
//                .scaledToFill()
//                .clipped()
//            )
//            .contentShape(Rectangle())
//            .aspectRatio(1, contentMode: .fit)
//            .clipped()
            Image("IMG_3284")
                .resizable()
                .matchedGeometryEffect(id: selected!, in: photo)
                .zIndex(1)
                .scaledToFit()
                .onTapGesture {
                    withAnimation {
                        selected = nil
                    }
                }
        }
    }
}

extension Image {
    @warn_unqualified_access
    func square() -> some View {
        Rectangle()
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                self
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(Rectangle())
    }
}
