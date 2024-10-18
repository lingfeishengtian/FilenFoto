//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import Photos
import PhotosUI
import AVKit

// TODO: make this better
var initSync: Bool = false

struct ContentView: View {
    @Namespace private var animation
    @ObservedObject var progress: SyncProgressInfo
    @ObservedObject var databaseStream: PhotoDatabaseStreamer
    
    @State var selectedDbPhotoAsset: DBPhotoAsset? = nil
    @State var showProgressMenu: Bool = false
    @State var fullImageView: Bool = false
    @State var inAnimation: Bool = false
    @State var searchBarShow: Bool = false
    
    @State var searchText: String = ""
    
    init () {
        let streamer = PhotoDatabaseStreamer()
        self.databaseStream = streamer
        self.progress = SyncProgressInfo {
            streamer.addMoreToLazyArray()
        }
        self.databaseStream.addMoreToLazyArray()
    }
    
    var body: some View {
        let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .purple, location: 0),
                .init(color: .clear, location: 0.4)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
        if fullImageView {
            FullImageView(isPresented: $fullImageView, inAnimation: $inAnimation, currentDbPhotoAsset: selectedDbPhotoAsset!, animation: animation)
        } else {
            ZStack{
                VStack {
                    HStack{
                        if searchBarShow {
                        } else {
                            Spacer()
                            if progress.progress >= 0.99 {
                                Circle()
                                    .fill(Color.blue)
                                    .matchedGeometryEffect(id: "searchbar", in: animation)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .bold))
                                    )
                                    .padding()
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            searchBarShow.toggle()
                                        }
                                    }
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        VStack {
                            HStack {
                                Text("ライブラリ")
                                    .font(.largeTitle)
                                    .bold()
                                Spacer()
                            }
                            HStack {
                                Text("\(progress.getTotalProgress().totalImages)項目 ")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                            }
                        }
                        Spacer()
                        VStack {
                            Menu {
                                Button(action: {
                                    let _ = PhotoVisionDatabaseManager.shared.startSync(existingSync: progress)
                                }) {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }.disabled(progress.progress < 0.99)
                            } label: {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.white)
                                            .font(.system(size: 24, weight: .bold))
                                    )
                            }
                        }
                    }
                    .padding()
                }.zIndex(1)
                VStack {
                    if searchBarShow {
                        TextField("Search", text: $searchText)
                            .padding(3)
                            .matchedGeometryEffect(id: "searchbar", in: animation)
                            .background(Color.gray.opacity(0.25))
                            .cornerRadius(15)
                            .padding()
                            .onChange(of: searchText) { newVal in
                                if newVal.count > 0 {
                                    Task {
                                        self.databaseStream.searchStream(searchQuery: newVal)
                                    }
                                } else {
                                    Task {
                                        self.databaseStream.defaultStream()
                                    }
                                }
                            }
                    }
                    if progress.progress < 0.99 {
                        HStack {
                            ProgressView(value: progress.progress)
                                .padding([.leading])
                            if progress.getTotalProgress().totalImages > 0 {
                                Text("\(progress.getTotalProgress().completedImages)/\(progress.getTotalProgress().totalImages)")
                            }
                            Menu {
                                ForEach(progress.getLastChanged(), id: \.phAsset.localIdentifier) { progIndicator in
                                    HStack {
                                        Label(progIndicator.internalMessage, systemImage: progIndicator.phAsset.mediaType == .image ? "photo" : "video")
                                    }
                                }
                            } label: {
                                Image(systemName: "info.circle.fill")
                            }
                            .padding([.trailing])
                        }
                    }
                    ScrollView {
                        if !databaseStream.lazyArray.sortedArray.isEmpty {
                            LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                                ForEach(databaseStream.lazyArray.sortedArray, id: \.localIdentifier) { dbPhotoAsset in
                                    let uiImage = UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName).path)
                                    
                                    Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
                                        .resizable()
                                        .matchedGeometryEffect(id: "thumbnailImageTransition" + dbPhotoAsset.localIdentifier, in: animation)
                                        .scaledToFill()
                                    )
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipped()
                                    .contentShape(Rectangle())
                                    .onAppear() {
                                        Task {
                                            if dbPhotoAsset.localIdentifier == databaseStream.lazyArray.sortedArray.last?.localIdentifier {
                                                databaseStream.addMoreToLazyArray()
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        if #available(iOS 17.0, *) {
                                            withAnimation {
                                                inAnimation = true
                                                self.selectedDbPhotoAsset = dbPhotoAsset
                                                fullImageView = true
                                            } completion: {
                                                withAnimation {
                                                    inAnimation = false
                                                }
                                            }
                                        } else {
                                            withAnimation(.easeInOut) {
                                                fullImageView = true
                                                self.selectedDbPhotoAsset = dbPhotoAsset
                                            }
                                        }
                                    }
                                }
                            }.id(searchText)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                }
                
                // Dark blur overlay at the bottom
                VStack {
                    Spacer()
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                                   startPoint: .bottom,
                                   endPoint: .center)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea(.all)
                    .frame(height: 300)
                    .allowsHitTesting(false)
                }
            }.onAppear {
                if !initSync {
                    let _ = PhotoVisionDatabaseManager.shared.startSync(existingSync: progress)
                    initSync = true
                }
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                       startPoint: .bottom,
                       endPoint: .center)
        .edgesIgnoringSafeArea(.all)
        .ignoresSafeArea(.all)
        .frame(height: 300)
    }
}

struct FullImageView: View {
    @Binding var isPresented: Bool
    @Binding var inAnimation: Bool
    @ObservedObject var viewManager: ViewManager
    let currentDbPhotoAsset: DBPhotoAsset
    let animation: Namespace.ID
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    @State private var viewOffset = CGSize.zero // To track the total offset
    @State private var dragOffset = CGSize.zero // To track the current drag
    let scalingFactor: CGFloat = 0.5
    
    init(isPresented: Binding<Bool>, inAnimation: Binding<Bool>, currentDbPhotoAsset: DBPhotoAsset, animation: Namespace.ID) {
        self._isPresented = isPresented
        self._inAnimation = inAnimation
        self.viewManager = ViewManager(dbAsset: currentDbPhotoAsset)
        self.currentDbPhotoAsset = currentDbPhotoAsset
        self.animation = animation
    }
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeInOut) {
                    self.isPresented = false
                }
            }) {
                Image(systemName: "arrowshape.backward.fill")
                    .padding()
            }
            if #available(iOS 17.0, *) {
                viewManager.view
                    .matchedGeometryEffect(id: "thumbnailImageTransition" + currentDbPhotoAsset.localIdentifier, in: animation)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .offset(x: viewOffset.width + dragOffset.width, y: viewOffset.height + dragOffset.height) // Apply both total and drag offset
                    .opacity(2 - Double(abs(viewOffset.width / 150)))
                    .scaledToFit()
                    .scaleEffect(currentZoom + totalZoom)
                    .gesture(DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            dragOffset = CGSize(
                                width: value.translation.width * scalingFactor,
                                height: value.translation.height * scalingFactor
                            )
                        }
                        .onEnded { value in
                            // Add the drag offset to the total offset when the drag ends
                            viewOffset.width += value.translation.width * scalingFactor
                            viewOffset.height += value.translation.height * scalingFactor
                            
                            // Reset the drag offset
                            dragOffset = .zero
                            
                            // Close view if dragged too far
                            if abs(viewOffset.width) > 100 || abs(viewOffset.height) > 100 {
                                withAnimation(.easeInOut) {
                                    self.isPresented = false
                                }
                            }
                        }
                    )
                    .simultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in
                                currentZoom = value.magnification - 1
                            }
                            .onEnded { value in
                                totalZoom += currentZoom
                                currentZoom = 0
                            }
                    )
                    .accessibilityZoomAction { action in
                        if action.direction == .zoomIn {
                            totalZoom += 1
                        } else {
                            totalZoom -= 1
                        }
                    }
            } else {
                viewManager.view
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .scaledToFit()
                    .scaleEffect(currentZoom + totalZoom)
                    .gesture(DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            dragOffset = CGSize(
                                width: value.translation.width * scalingFactor,
                                height: value.translation.height * scalingFactor
                            )
                        }
                        .onEnded { value in
                            // Add the drag offset to the total offset when the drag ends
                            viewOffset.width += value.translation.width * scalingFactor
                            viewOffset.height += value.translation.height * scalingFactor
                            
                            // Reset the drag offset
                            dragOffset = .zero
                            
                            // Close view if dragged too far
                            if abs(viewOffset.width) > 300 || abs(viewOffset.height) > 300 {
                                withAnimation(.easeInOut) {
                                    self.isPresented = false
                                }
                            }
                        }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentZoom = value.magnitude - 1
                            }
                            .onEnded { value in
                                totalZoom += currentZoom
                                currentZoom = 0
                            }
                    )
                    .accessibilityZoomAction { action in
                        if action.direction == .zoomIn {
                            totalZoom += 1
                        } else {
                            totalZoom -= 1
                        }
                    }
            }
        }.onAppear {
            Task {
                await viewManager.getView()
            }
        }
    }
}

class ViewManager: ObservableObject {
    let dbAsset: DBPhotoAsset
    @Published var view: AnyView
    var imgPath: String
    
    init(dbAsset: DBPhotoAsset) {
        self.dbAsset = dbAsset
        self.imgPath = FullSizeImageCache.getFullSizeImageOrThumbnail(for: dbAsset).path
        self.view = AnyView(Image(uiImage: UIImage(contentsOfFile: imgPath) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fit))
    }
    
    func setView(_ view: some View) {
        DispatchQueue.main.async {
            withAnimation {
                self.view = AnyView(view)
            }
        }
    }
    
    func getView() async {
        if dbAsset.mediaType == .image {
            if dbAsset.mediaSubtype.contains(.photoLive) {
                let livePhotoAssets = await FullSizeImageRetrieval.shared.getLiveImageResources(asset: dbAsset)
                if livePhotoAssets != nil {
                    PHLivePhoto.request(withResourceFileURLs: [livePhotoAssets!.photoUrl, livePhotoAssets!.videoUrl], placeholderImage: nil, targetSize: CGSizeZero, contentMode: .aspectFit, resultHandler: { lPhoto, info in
                        self.setView(AnyView(UIKitLivePhotoView(livephoto: lPhoto)))
                    })
                }
            } else {
                let photoAssets = await FullSizeImageRetrieval.shared.getImageResource(asset: dbAsset)
                if let img = photoAssets, imgPath != img.path {
                    setView(AnyView(
                        Image(uiImage: UIImage(contentsOfFile: img.path) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)))
                }
            }
        } else if dbAsset.mediaType == .video {
            let videoAssets = await FullSizeImageRetrieval.shared.getVideoResource(asset: dbAsset)
            if let vid = videoAssets {
                await setView(AnyView(VideoPlayer(player: AVPlayer(url: vid))))
            }
        }
    }
}

struct UIKitLivePhotoView: UIViewRepresentable {
    let livephoto: PHLivePhoto?
    
    func makeUIView(context: Context) -> PHLivePhotoView {
        return PHLivePhotoView()
    }
    
    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livephoto
    }
}
