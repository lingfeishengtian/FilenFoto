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
    @State private var fanOut = false
    
    var body: some View {
        ZStack {
            //            PhotoCarousel()
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
                            Text("\(photoEnvironment.getTotalProgress().totalImages)項目 ")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.bold()
                        Spacer()
                        VStack {
                            Menu {
                                Button(action: {
                                    let _ = PhotoVisionDatabaseManager.shared.startSync(
                                        existingSync: photoEnvironment)
                                }) {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }.disabled(photoEnvironment.progress < 0.99)
                            } label: {
                                IconView(size: .medium, iconSystemName: "ellipsis")
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Text("検索")
                            .font(.largeTitle)
                            .bold()
                            .padding([.leading], 10)
                            .padding([.bottom], 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if searchText.count == 0 {
                            Text("Popular Categories")
                                .font(.subheadline)
                                .bold()
                                .padding([.leading], 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            PopularCategoryTags()
                                .padding([.leading, .trailing])
                                .animation(.easeInOut, value: searchText.count == 0)
                            Spacer()
                            FanOutListView(
                                history: photoEnvironment.searchHistoryCache,
                                onChangeValueClicked: { val in
                                    withAnimation {
                                        fanOut = false
                                        searchText = val
                                        photoEnvironment.addNewSearchHistory(searchQuery: val)
                                    }
                                })
                        } else {
                            Spacer()
                        }
                        TextField("Search", text: $searchText)
                            .paddedRounded(fill: Color(UIColor.darkGray).opacity(0.7))
                            .foregroundStyle(.white)
                            .focused($keyboardFocus)
                            .onChange(of: keyboardFocus) { bool in
                                withAnimation {
                                    fanOut = bool
                                }
                            }
                            .matchedGeometryEffect(id: "searchbar", in: animation)
                            .onChange(of: searchText) { newVal in
                                if newVal.count > 0 {
                                    Task {
                                        photoEnvironment.searchStream(searchQuery: newVal)
                                    }
                                } else {
                                    Task {
                                        photoEnvironment.defaultStream()
                                    }
                                }
                            }
                            .onAppear {
                                keyboardFocus = true
                            }
                            .onSubmit {
                                withAnimation {
                                    if searchText.count == 0 {
                                        searchBarShow = false
                                        keyboardFocus = false
                                    } else {
                                        withAnimation {
                                            photoEnvironment.addNewSearchHistory(
                                                searchQuery: searchText)
                                        }
                                    }
                                }
                            }
                    }.padding()
                }
            }.zIndex(2)
            VStack {
                if photoEnvironment.progress < 0.99 {
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
                                photoEnvironment.getLastChanged(), id: \.phAsset.localIdentifier
                            ) { progIndicator in
                                HStack {
                                    Label(
                                        progIndicator.internalMessage,
                                        systemImage: progIndicator.phAsset.mediaType == .image
                                        ? "photo" : "video")
                                }
                            }
                        } label: {
                            Image(systemName: "info.circle.fill")
                        }
                        .padding([.trailing])
                    }
                }
                
                ScrollViewReader { value in
                    ScrollView {
                        if !photoEnvironment.lazyArray.sortedArray.isEmpty {
                            LazyVGrid(
                                columns: [
                                    .init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)
                                ], spacing: 3
                            ) {
                                ForEach(
                                    photoEnvironment.lazyArray.sortedArray, id: \.localIdentifier
                                ) { dbPhotoAsset in
                                    //                                                        ThumbnailView(thumbnailName: dbPhotoAsset.thumbnailFileName)
                                    Color.clear.background(Image(uiImage: UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) ?? UIImage())
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                    )
                                    .contentShape(Rectangle())
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipped()
                                    .opacity(
                                        (photoEnvironment.selectedDbPhotoAsset == dbPhotoAsset && photoEnvironment.shouldShowFullImageView == true)
                                        ? 0 : 1
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
                                            photoEnvironment.shouldShowFullImageView = true
                                        }
                                    }
                                    .matchedGeometryEffect(
                                        id: "thumbnailImageTransition"
                                        + dbPhotoAsset.localIdentifier, in: animation)
                                    .onAppear {
                                        if dbPhotoAsset.localIdentifier == photoEnvironment.lazyArray.sortedArray.last?.localIdentifier {
                                            Task {
                                                await photoEnvironment.addMoreToLazyArray()
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .onChange(of: photoEnvironment.selectedDbPhotoAsset) {
                                if let selected = photoEnvironment.selectedDbPhotoAsset?.localIdentifier {
                                    value.scrollTo(selected)
                                }
                            }
                        }
                    }
                }
            }
            .blur(radius: (searchText.count == 0 && searchBarShow) ? 10 : 0)
            .disabled(searchText.count == 0 && searchBarShow)
            .animation(.easeInOut, value: (searchText.isEmpty && searchBarShow))
            //                }
            //            }
            //            if let selected = photoEnvironment.selectedDbPhotoAsset {
            //                ThumbnailView(dbPhotoAsset: selected)
            //                    .matchedGeometryEffect(
            //                        id: "thumbnailImageTransition"
            //                        + dbPhotoAsset.localIdentifier, in: animation)
            //            }
            
        }
        .onAppear {
            photoEnvironment.setOnComplete {
                Task {
                    await photoEnvironment.addMoreToLazyArray()
                }
            }
            Task {
#if DEBUG
                if let isPrev = ProcessInfo.processInfo.environment[
                    "XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1"
                {
                    photoEnvironment.progress = 1.0
                    let dbPhotoAsset: DBPhotoAsset = .init(
                        id: -1, localIdentifier: "testImage", mediaType: .image,
                        mediaSubtype: .photoHDR,
                        creationDate: Date.now - 1_000_000, modificationDate: Date.now,
                        location: CLLocation(latitude: 0, longitude: 0), favorited: false,
                        hidden: false,
                        thumbnailFileName: "meow.jpg")
                    photoEnvironment.lazyArray.insert(
                        dbPhotoAsset
                    )
                    photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
                } else {
                    await photoEnvironment.addMoreToLazyArray()
                    let _ = PhotoVisionDatabaseManager.shared.startSync(
                        existingSync: photoEnvironment)
                }
#else
                await photoEnvironment.addMoreToLazyArray()
                let _ = PhotoVisionDatabaseManager.shared.startSync(
                    existingSync: photoEnvironment)
#endif
            }
        }
        .environmentObject(photoEnvironment)
        .overlay {
            if photoEnvironment.shouldShowFullImageView {
                //                ZoomablePhoto(scale: .constant(1.0), offset: .constant(.init(width: 0, height: 0)), onSwipeUp: {}, onSwipeDown: {}, image: .constant(UIImage(named: "IMG_3284")!))
                //                NavigationStack {
                FullImageView(
                    currentDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset!,
                    animation: animation
                )
                .environmentObject(photoEnvironment)
                //                }
            }
        }
    }
}
