//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import Photos
import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @Namespace var animation
    @StateObject var photoEnvironment: PhotoEnvironment = PhotoEnvironment()
    @State var showProgressMenu: Bool = false
    @State var inAnimation: Bool = false
    @State var searchBarShow: Bool = false
    @State var searchText: String = ""
    @FocusState var keyboardFocus: Bool
    
    func initiateSyncTask() {
        Task {
            DispatchQueue.main.async {
                let _ = PhotoVisionDatabaseManager.shared.startSync(
                    onNewDatabasePhotoAdded:  { dbPhoto in
                        DispatchQueue.main.async {
                            self.photoEnvironment.eventPhotoInserted(dbPhoto)
                        }
                    }, progressInfo: photoEnvironment)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        if searchBarShow {
                        } else {
                            Spacer()
                            if photoEnvironment.progress >= 0.99 {
                                IconView(size: .small, iconSystemName: "magnifyingglass")
                                    .padding()
                                    .matchedGeometryEffect(id: "searchbar", in: animation)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            self.searchBarShow = true
                                        }
                                    }
                            }
                        }
                    }
                    Spacer()
                    if !searchBarShow {
                        HStack {
                            VStack {
                                Text("ライブラリ")
                                    .font(.largeTitle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(photoEnvironment.countOfPhotos)項目 ")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.bold()
                            Spacer()
                            VStack {
                                Menu {
                                    Button(action: {
                                        initiateSyncTask()
                                    }) {
                                        Label("Refresh", systemImage: "arrow.clockwise")
                                    }.disabled(photoEnvironment.progress < 0.99)
                                    NavigationLink {
                                        Settings()
                                            .environmentObject(photoEnvironment)
                                    } label: {
                                        Label("Settings", systemImage: "gear")
                                    }
                                } label: {
                                    IconView(size: .medium, iconSystemName: "ellipsis")
                                }
                            }
                        }
                        .padding()
                    } else {
                        SearchView(searchBarShow: $searchBarShow, searchText: $searchText, keyboardFocus: $keyboardFocus, animation: animation)
                            .environmentObject(photoEnvironment)
                    }
                }.zIndex(2)
                PhotoScroller(
                    keyboardFocus: $keyboardFocus,
                    animation: animation
                )
                .blur(radius: (searchBarShow) ? 10 : 0)
                .disabled(searchBarShow)
                .animation(.easeInOut, value: (searchText.isEmpty && searchBarShow))
            }
            .environmentObject(photoEnvironment)
            .overlay {
                if photoEnvironment.shouldShowFullImageView && photoEnvironment.selectedDbPhotoAsset != nil {
                    FullImageView(animation: animation)
//                    TestImageFull(dbAsset: photoEnvironment.selectedDbPhotoAsset!, animation: animation, shouldShowFullImageView: $photoEnvironment.shouldShowFullImageView)
                       .environmentObject(photoEnvironment)
                }
            }
        }
        .onAppear {
//            photoEnvironment.countOfPhotos = 2000
            photoEnvironment.countOfPhotos = PhotoDatabase.shared.getCountOfPhotos()
            initiateSyncTask()
        }
    }
}

#Preview {
    ContentView()
}

struct PhotoScroller: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @FocusState.Binding var keyboardFocus: Bool
    let animation: Namespace.ID
    
    @State var scrollPosition: ScrollPosition = .init(id: 0)
    @State var isScrolling: Bool = false
    
    var body: some View {
        VStack {
            GeometryReader { reader in
                ScrollView {
                    VStack {
                        if photoEnvironment.progress < 0.99 {
                            VStack {
                                Text("Sync Progress")
                                    .font(.title2)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .padding(.horizontal)
                                HStack {
                                    ProgressView(value: photoEnvironment.progress)
                                        .padding([.leading])
                                    if photoEnvironment.getTotalProgress().totalImages > 0 {
                                        Text(
                                            "\(photoEnvironment.getTotalProgress().completedImages)/\(photoEnvironment.getTotalProgress().totalImages)"
                                        )
                                    }
                                    Menu {
                                        ForEach(
                                            photoEnvironment.getLastChanged(), id: \.phAssetLocalIdentifier
                                        ) { progIndicator in
                                            HStack {
                                                Label(
                                                    progIndicator.internalMessage,
                                                    systemImage: progIndicator.isImage
                                                    ? "photo" : "video")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "info.circle.fill")
                                    }
                                    .padding([.trailing])
                                }.padding([.leading, .trailing, .bottom])
                            }.background {
                                Color.black
                                    .ignoresSafeArea(.all)
                            }
                            Spacer()
                        }
                    }
                    .animation(.bouncy, value: photoEnvironment.progress)
                    //                    if !photoEnvironment.lazyArray.sortedArray.isEmpty {
                    LazyPhotoGrid(
                        keyboardFocus: $keyboardFocus,
                        animation: animation
                    )
                    //                    }
                    
                    VStack {
                        Text(" ")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(" ")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.bold()
                        .hidden()
                        .padding([.top])
                }
//                .scrollPosition($scrollPosition, anchor: .top)
//                    .onChange(of: photoEnvironment.shouldShowFullImageView) {
//                        if let selected = photoEnvironment.selectedDbPhotoAsset?.localIdentifier, !photoEnvironment.shouldShowFullImageView, let ind = photoEnvironment.getCurrentPhotoAssetIndex() {
//                            scrollPosition.scrollTo(y: (reader.size.width) * CGFloat((ind / 3 - 1)))
//                        }
//                    }
            }
        }
    }
}
