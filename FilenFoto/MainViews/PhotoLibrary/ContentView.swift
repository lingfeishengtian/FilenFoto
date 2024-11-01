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
    
    func initiateSyncTask() {
        Task {
            DispatchQueue.main.async {
                let _ = PhotoVisionDatabaseManager.shared.startSync(
                    onNewDatabasePhotoAdded:  { dbPhoto in
                        DispatchQueue.main.async {
//                            self.photoEnvironment.lazyArray.insert(dbPhoto)
//                            self.photoEnvironment.countOfPhotos = PhotoDatabase.shared.getCountOfPhotos()
                            self.photoEnvironment.eventPhotoInserted(dbPhoto)
                        }
                    }, existingSync: photoEnvironment)
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
                                .onChange(of: keyboardFocus) {
                                    withAnimation {
                                        fanOut = keyboardFocus
                                    }
                                }
                                .matchedGeometryEffect(id: "searchbar", in: animation)
                                .onChange(of: searchText) {
                                    if searchText.count > 0 {
                                        Task {
                                            photoEnvironment.searchStream(searchQuery: searchText)
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
                PhotoScroller(
                    keyboardFocus: $keyboardFocus,
                    animation: animation
                )
                .blur(radius: (searchText.count == 0 && searchBarShow) ? 10 : 0)
                .disabled(searchText.count == 0 && searchBarShow)
                .animation(.easeInOut, value: (searchText.isEmpty && searchBarShow))
            }
            .onAppear {
                photoEnvironment.countOfPhotos = PhotoDatabase.shared.getCountOfPhotos()
                initiateSyncTask()
            }
            .environmentObject(photoEnvironment)
            .overlay {
                if photoEnvironment.shouldShowFullImageView {
                    FullImageView(animation: animation)
                        .environmentObject(photoEnvironment)
                }
            }
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
                }.scrollPosition($scrollPosition, anchor: .top)
                    .onChange(of: photoEnvironment.selectedDbPhotoAsset) {
                        if let selected = photoEnvironment.selectedDbPhotoAsset?.localIdentifier, photoEnvironment.shouldShowFullImageView, let ind = photoEnvironment.getCurrentPhotoAssetIndex() {
                            scrollPosition.scrollTo(y: (reader.size.width) * CGFloat((ind / 3 - 1)))
                        }
                    }
            }
        }
    }
}
