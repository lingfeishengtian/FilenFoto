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
                                    Color.clear.background(Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName).path) ?? UIImage())
                                        .resizable()
                                        .scaledToFill())
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipped()
                                        .opacity(
                                            (photoEnvironment.selectedDbPhotoAsset == dbPhotoAsset)
                                            ? 0 : 1
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
                                            }
                                        }
                                        .matchedGeometryEffect(
                                            id: "thumbnailImageTransition"
                                            + dbPhotoAsset.localIdentifier, in: animation)
                                }
                                // test for each of 20k items
                                //                                                                       ForEach(0..<20_000) { i in
                                ////                                                                           if let dbAsset = photoEnvironment.lazyArray.sortedArray.first {
                                ////                                                                               ThumbnailView(thumbnailName: dbAsset.thumbnailFileName)
                                ////                                                                           }
                                //                                                                           Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: photoEnvironment.lazyArray.sortedArray.first?.thumbnailFileName ?? "").path) ?? UIImage())
                                //                                                                               .resizable()
                                //                                                                               .scaledToFit()
                                //                                                                               .aspectRatio(1, contentMode: .fit)
                                //                                                                               .clipped()
                                //                                                                       }
                            }
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            //                    GridView { dbPhotoAsset in
                            //                        ThumbnailView(dbPhotoAsset: dbPhotoAsset)
                            //                            .opacity(
                            //                                (photoEnvironment.selectedDbPhotoAsset == dbPhotoAsset)
                            //                                    ? 0 : 1
                            //                            )
                            //                        //                            .matchedGeometryEffect(
                            //                        //                                id: "thumbnailImageTransition"
                            //                        //                                + dbPhotoAsset.localIdentifier, in: animation)
                            //                    } onCellSelected: { asset in
                            //                        withAnimation {
                            //                            photoEnvironment.selectedDbPhotoAsset = asset
                            //                        }
                            //                    }.frame(maxHeight: .infinity, alignment: .bottom)
                            //                        .ignoresSafeArea(.all)
                        }
                    }
                }

                //                Text("")
                //                    .paddedRounded(fill: .clear)
                //                    .padding()
                //                    .background(Color.black.opacity(0.5))
                //                    .cornerRadius(8)
                //                    .overlay(
                //                        Rectangle()
                //                            .fill(Color.clear)
                //                    )
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
            if photoEnvironment.selectedDbPhotoAsset != nil {
                FullImageView(
                    currentDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset!,
                    animation: animation
                )
                .environmentObject(photoEnvironment)
            }
        }
    }
}

// struct FullImageView: View {
//     @EnvironmentObject var photoEnvironment: PhotoEnvironment

//     @State private var currentDbPhotoAsset: DBPhotoAsset

//     @State private var scale: CGFloat = 1.0
//     @State private var offset: CGSize = .zero
//     @State private var isDragging = false
//     @State private var dismissThreshold: CGFloat = 200
//     @State private var isScrolling = true
    
//     @State private var assetFileUrl: URL?
//     @State private var showDetail: Bool = true

//     let formatter = RelativeDateTimeFormatter()

//     let animation: Namespace.ID

//     init(currentDbPhotoAsset: DBPhotoAsset, animation: Namespace.ID) {
//         self.currentDbPhotoAsset = currentDbPhotoAsset
//         self.animation = animation
//         formatter.unitsStyle = .full
//         formatter.locale = Locale(identifier: "ja_JP")
//     }

//     var body: some View {
//         VStack {
// //            if !showDetail {
//                 HStack {
//                     Text(
//                         formatter.localizedString(
//                             for: currentDbPhotoAsset.creationDate, relativeTo: Date.now)
//                     )
//                     .font(.largeTitle)
//                     .foregroundStyle(.white)
//                     Spacer()
//                     Button {
//                         withAnimation {
//                             photoEnvironment.selectedDbPhotoAsset = nil
//                         }
//                     } label: {
//                         IconView(size: .small, iconSystemName: "xmark")
//                     }
//                 }.padding([.leading, .trailing], 30)
//                 Spacer()
// //            }
//             ViewManager(
//                 scale: $scale, offset: $offset, onSwipeUp: {
//                     withAnimation {
//                         print("Scroll up")
//                         showDetail = true
//                     }
//                 }, isScrolling: $isScrolling,
//                 onSwipeDown: {
//                     if showDetail {
// //                        withAnimation {
// //                            showDetail.toggle()
// //                        }
//                     } else {
//                         offset.height = dismissThreshold
//                         withAnimation(.snappy) {
//                             photoEnvironment.selectedDbPhotoAsset = nil
//                         }
//                     }
//                 }, assetFileUrl: $assetFileUrl
//             ).frame(maxWidth: .infinity, maxHeight: .infinity)
//                 .matchedGeometryEffect(id: "image", in: animation)
//             Spacer()
//             if !showDetail {
//                 PhotoScrubberView(itemsToShow: 5, spacing: 10, scrollState: $isScrolling)
//                     .frame(height: 60)
//                     .opacity(
//                         Double(
//                             1 - ((abs(offset.height) + (scale - 1) * dismissThreshold)
//                                  / dismissThreshold)))
//             }
//             HStack {
//                 if let assetFileUrl {
//                     ShareLink(item: assetFileUrl) {
//                         IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                     }
//                 } else {
//                     IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                         .disabled(assetFileUrl == nil)
//                 }
//                 Spacer()
//                 Button {
// //                    withAnimation {
// //                        showDetail.toggle()
// //                    }
//                 } label: {
//                     IconView(size: .medium, iconSystemName: "info.circle")
//                 }
//                 Spacer()
//             }.padding()
//                 .padding(.horizontal, 10)
                
            
// //            if showDetail {
//             //            }
//         }
//         .overlay {
// //            if showDetail {
//                 PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset, showDetail: $showDetail, offset: $offset, animation: animation)
//                     .offset(offset)
// //            }
// //            let heightConstraint = offset.height * 3
// //            GeometryReader { reader in
// //                NavigationStack {
// //                    PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset)
// //                    Spacer()
// //                }
// //                .offset(
// //                    x: 0,
// //                    y: reader.size.height
// //                    - (showDetail ? 400 - heightConstraint : -heightConstraint)
// //                )
// //                .transition(.move(edge: .bottom))
// //            }
// //            .ignoresSafeArea(.all)
// //            .animation(.easeInOut, value: showDetail)
//         }
//         .background {
//             Color.black.opacity(Double(1 - (offset.height / dismissThreshold)))
//                 .ignoresSafeArea(.all)
//                 .allowsHitTesting(photoEnvironment.selectedDbPhotoAsset != nil)
//         }
        
//         //            GeometryReader { reader in
//         //                let heightConstraint = offset.height * 3
// //                let _ = print(heightConstraint)
// //
// //                VStack {
// //                    Spacer()
// //                    PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset)
// //                        .frame(height: 400)
// //                        .background(Color.white)
// //                        .cornerRadius(20)
// //                        .shadow(radius: 10)
// //                        .offset(
// //                            x: 0,
// //                            y: reader.size.height
// //                                - (showDetail ? 400 - heightConstraint : -heightConstraint)
// //                        )
// //                        .transition(.move(edge: .bottom))
// //                }
// //                .ignoresSafeArea(.all)
// //            }
//     }
// }

// struct PhotoDetails: View {
//     @Binding var currentDbPhotoAsset: DBPhotoAsset
//     @Binding var showDetail: Bool
//     @Binding var offset: CGSize
//     let animation: Namespace.ID

//     var body: some View {
// //        Image(uiImage: UIImage(contentsOfFile: FullSizeImageCache.getFullSizeImageOrThumbnail(for: currentDbPhotoAsset).path) ?? UIImage())
//         List {
// //#if targetEnvironment(simulator)
// //        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
// //            let randomColors = [
// //                UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.orange,
// //                UIColor.purple, UIColor.cyan, UIColor.magenta,
// //            ]
// //            Image(uiImage: currentDbPhotoAsset.localIdentifier.image(withAttributes: [
// //                .foregroundColor: UIColor.red,
// //                .font: UIFont.systemFont(ofSize: 10.0),
// //                .backgroundColor: randomColors.randomElement()!,
// //            ]) ?? UIImage())
// //            .resizable()
// //            .scaledToFit()
// //            .matchedGeometryEffect(id: "image", in: animation)
// //        }
// //#endif
//             Section {
//                 Label {
//                     Text("Creation")
//                     Text(currentDbPhotoAsset.creationDate.formatted())
//                 } icon: {
//                     if currentDbPhotoAsset.mediaType == .image {
//                         if currentDbPhotoAsset.mediaSubtype.contains(.photoLive) {
//                             Image(systemName: "livephoto")
//                         } else {
//                             Image(systemName: "photo")
//                         }
//                     } else {
//                         Image(systemName: "video")
//                     }
//                 }
                
//                 if let location = currentDbPhotoAsset.location {
//                     MapView(location: location)
//                         .frame(height: 200)
//                         .cornerRadius(20)
//                 }
//             }
//         }.scrollDisabled(true)
//             .gesture(DragGesture().onChanged { value in
//                 let translation = value.translation
//                 offset = translation
// //                if translation.height > 0 {
// //                    withAnimation {
// //                        showDetail = false
// //                    }
// //                }
//             })
//     }
// }

// struct MapView: View {
//     var location: CLLocation

//     @State private var region: MKCoordinateRegion

//     init(location: CLLocation) {
//         self.location = location
//         _region = State(
//             initialValue: MKCoordinateRegion(
//                 center: location.coordinate,
//                 span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//             ))
//     }

//     var body: some View {
//         Map(coordinateRegion: $region, annotationItems: [location]) { location in
//             MapAnnotation(coordinate: location.coordinate) {
//                 Image(systemName: "mappin.circle.fill")
//                     .foregroundColor(.red)
//                     .font(.title)
//             }
//         }
//         .edgesIgnoringSafeArea(.all)
//     }
// }

// extension CLLocation: Identifiable {
//     public var id: CLLocation {
//         self
//     }
// }
