import SwiftUI
import CoreLocation
import MapKit

struct FullImageView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    
    @State private var currentDbPhotoAsset: DBPhotoAsset
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var sheetOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dismissThreshold: CGFloat = 200
    @State private var isScrolling = true
    
    @State private var assetFileUrl: URL?
    @State private var showDeleteAlert: Bool = false
    @State private var showDetail: Bool = false
    
    let formatter = RelativeDateTimeFormatter()
    
    let animation: Namespace.ID
    
    init(currentDbPhotoAsset: DBPhotoAsset, animation: Namespace.ID) {
        self.currentDbPhotoAsset = currentDbPhotoAsset
        self.animation = animation
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
    }
    //TODO: Add loading icon on top
    var body: some View {
        let selectOrCurrent = photoEnvironment.selectedDbPhotoAsset ?? currentDbPhotoAsset

        VStack {
            HStack {
                Text(
                    formatter.localizedString(
                        for: currentDbPhotoAsset.creationDate, relativeTo: Date.now)
                )
                .font(.largeTitle)
                .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation {
                        photoEnvironment.selectedDbPhotoAsset = nil
                    }
                } label: {
                    IconView(size: .small, iconSystemName: "xmark")
                }
            }.padding([.leading, .trailing], 30)
                .frame(maxHeight: showDetail ? 0 : nil)
                .opacity(showDetail ? 0 : 1)
            Spacer()
            VStack {
                GeometryReader { reader in
                    ScrollViewReader { proxyScroll in
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                ForEach(photoEnvironment.lazyArray.sortedArray[photoEnvironment.lazyArray.binSearch(selectOrCurrent)-1...photoEnvironment.lazyArray.binSearch(selectOrCurrent)+1], id: \.self) { dbAsset in
                                    if dbAsset == photoEnvironment.selectedDbPhotoAsset {
                                        ViewManager(
                                            scale: $scale, offset: $offset, onSwipeUp: {
                                                //                     withAnimation {
                                                //                         offset.height = 60
                                                //                     }
                                            }, isScrolling: $isScrolling,
                                            onSwipeDown: {
                                                if showDetail || offset.height < 0 {
                                                    withAnimation {
                                                        showDetail = false
                                                    }
                                                } else {
                                                    offset.height = dismissThreshold
                                                    withAnimation(.snappy) {
                                                        photoEnvironment.selectedDbPhotoAsset = nil
                                                    }
                                                }
                                            }, assetFileUrl: $assetFileUrl
                                        )
                                        .frame(width: reader.size.width, height: reader.size.height)
                                        .onChange(of: offset) {
                                            if offset.height < -10 {
                                                withAnimation {
                                                    print("Showing Detail")
                                                    self.showDetail = true
                                                    sheetOffset = .zero
                                                }
                                            } else if offset.height > 10 {
                                                withAnimation {
                                                    print("hiding Detail")
                                                    self.showDetail = false
                                                    sheetOffset = .zero
                                                }
                                            }
                                        }.matchedGeometryEffect(
                                            id: "thumbnailImageTransition"
                                            + currentDbPhotoAsset.localIdentifier, in: animation)
                                    } else {
                                        ZoomablePhoto(
                                            scale: $scale,
                                            offset: $offset,
                                            onSwipeUp: {
                                                //                     withAnimation {
                                                //                         offset.height = 60
                                                //                     }
                                            },
                                            onSwipeDown: {
                                                if showDetail || offset.height < 0 {
                                                    withAnimation {
                                                        showDetail = false
                                                    }
                                                } else {
                                                    offset.height = dismissThreshold
                                                    withAnimation(.snappy) {
                                                        photoEnvironment.selectedDbPhotoAsset = nil
                                                    }
                                                }
                                            },
                                            image: .constant(UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbAsset.thumbnailFileName).path) ?? UIImage()))
                                        .frame(width: reader.size.width, height: reader.size.height)
                                        .offset(showDetail ? .init(width: 0, height: sheetOffset.height) : .zero)
                                    }
                                    //                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }.scrollTargetLayout()
                        }
                            .scrollTargetBehavior(.paging)
                            .onAppear {
                                proxyScroll.scrollTo(currentDbPhotoAsset)
                            }
                            .scrollPosition(
                                id: .init(
                                    get: {
                                        photoEnvironment.selectedDbPhotoAsset
                                    },
                                    set: { value, transaction in
                                        if let value {
                                            photoEnvironment.selectedDbPhotoAsset = value
                                            //                                    print("Set \(photoEnvironment.lazyArray.binSearch(photoEnvironment.selectedDbPhotoAsset!))")
                                        }
                                    }
                                )
                            )
                    }
                }
                //                         if !showDetail {
                Spacer()
                PhotoScrubberView(itemsToShow: 5, spacing: 10, scrollState: $isScrolling)
                //                 PhotoCarousel(startDbPhotoAsset: currentDbPhotoAsset)
                    .frame(height: 60)
                    .opacity(
                        showDetail ? 0 : 1
                    )
                    .disabled(showDetail)
                HStack {
                    if let assetFileUrl {
                        ShareLink(item: assetFileUrl) {
                            IconView(size: .medium, iconSystemName: "square.and.arrow.up")
                        }
                    } else {
                        IconView(size: .medium, iconSystemName: "square.and.arrow.up")
                            .disabled(assetFileUrl == nil)
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            offset = .init(width: 0, height: -300)
                        }
                    } label: {
                        IconView(size: .medium, iconSystemName: "info.circle")
                    }
                    Spacer()
                    Button {
                        showDeleteAlert = true
                    } label: {
                        IconView(size: .medium, iconSystemName: "trash")
                    }
                }.padding()
                    .padding(.horizontal, 10)
                //                         }
                //                 }
                //                 .ignoresSafeArea(.all)
            }
        }
        .statusBarHidden(offset.height * 2 < -550)
        .background {
            Color.black.opacity(Double(1 - (offset.height / dismissThreshold)))
                .ignoresSafeArea(.all)
                .allowsHitTesting(photoEnvironment.selectedDbPhotoAsset != nil)
        }.confirmationDialog("Trash Item", isPresented: $showDeleteAlert)
        {
            Button("Confirm (this does nothing rn)", role: .destructive) {
                
            }
            Button("Cancel", role: .cancel) {
                
            }
        }
        .ignoresSafeArea(showDetail ? .all : .keyboard)
        .overlay {
            GeometryReader { reader in
                VStack {
                    PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset, showDetail: .constant(showDetail), offset: $offset, animation: animation)
                        .gesture(DragGesture().onChanged { value in
                            //                                 sheetOffset = value.translation
                            print("Sheet offset \(value.translation)")
                            print(" offset \(offset)")
                            //                                 if sheetOffset.height + offset.height > 0 {
                            //                                     print("Detail stopped ", sheetOffset.height, offset.height)
                            //                                     self.showDetail = false
                            //                                     sheetOffset = .zero
                            //                                 }
                        })
                }.offset(.init(width: 0, height: reader.size.height + (offset.height > -150 ? offset.height * 2 : offset.height - 150))) // TODO: Change to carousel height
                //                     .frame(maxWidth: reader.size.width, maxHeight: showDetail ? .infinity : 0)
            }
        }
    }
}

struct PhotoDetails: View {
    @Binding var currentDbPhotoAsset: DBPhotoAsset
    @Binding var showDetail: Bool
    @Binding var offset: CGSize
    let animation: Namespace.ID
    
    var body: some View {
        VStack {
            List {
                Section {
                    Label {
                        Text("Creation")
                        Text(currentDbPhotoAsset.creationDate.formatted())
                    } icon: {
                        if currentDbPhotoAsset.mediaType == .image {
                            if currentDbPhotoAsset.mediaSubtype.contains(.photoLive) {
                                Image(systemName: "livephoto")
                            } else {
                                Image(systemName: "photo")
                            }
                        } else {
                            Image(systemName: "video")
                        }
                    }
                    
                    if let location = currentDbPhotoAsset.location {
                        MapView(location: location)
                            .frame(height: 200)
                            .cornerRadius(20)
                    }
                }
            }.scrollDisabled(false)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom))
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom))
    }
}

struct MapView: View {
    var location: CLLocation
    
    @State private var region: MKCoordinateRegion
    
    init(location: CLLocation) {
        self.location = location
        _region = State(
            initialValue: MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [location]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension CLLocation: Identifiable {
    public var id: CLLocation {
        self
    }
}


#Preview {
    @Previewable @Namespace var animation
    let photoEnviornment = PhotoEnvironment()
    let dbPhotoAsset: DBPhotoAsset = .init(
        id: -1, localIdentifier: "testImage", mediaType: .image, mediaSubtype: .photoHDR,
        creationDate: Date.now - 1_000_000, modificationDate: Date.now,
        location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
        thumbnailFileName: "meow.jpg")
    photoEnviornment.lazyArray.insert(
        dbPhotoAsset
    )
    photoEnviornment.selectedDbPhotoAsset = dbPhotoAsset
    //    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
    //        .environmentObject(photoEnviornment)
    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
        .environmentObject(photoEnviornment)
}
