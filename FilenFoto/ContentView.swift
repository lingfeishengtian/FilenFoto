//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import Photos
import PhotosUI

struct ContentView: View {
    @Namespace private var animation
    @ObservedObject var progress: SyncProgressInfo
    @ObservedObject var databaseStream: PhotoDatabaseStreamer
    
    @State var selectedDbPhotoAsset: DBPhotoAsset? = nil
    
    init () {
        let streamer = PhotoDatabaseStreamer()
        self.databaseStream = streamer
        self.progress = PhotoVisionDatabaseManager.shared.startSync() {
            streamer.addMoreToLazyArray()
        }
        self.databaseStream.addMoreToLazyArray()
    }
    
    var body: some View {
        if selectedDbPhotoAsset != nil {
            FullImageView(selectedDbPhotoAsset: $selectedDbPhotoAsset, currentDbPhotoAsset: selectedDbPhotoAsset!, animationId: animation)
                .matchedGeometryEffect(id: "thumbnailImageTransition" + selectedDbPhotoAsset!.localIdentifier, in: animation)
        } else {
            VStack {
                VStack {
                    Text(progress.currentStep)
                    Text("\(progress.amountOfImagesSynced)/\(progress.totalAmountOfImages)")
                    ProgressView(value: progress.progress)
                        .progressViewStyle(.linear)
                }.padding()
                ScrollView {
                    LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                        ForEach(databaseStream.lazyArray.sortedArray, id: \.localIdentifier) { dbPhotoAsset in
                            ThumbnailImage(dbPhotoAsset: dbPhotoAsset, selectedDbPhotoAsset: $selectedDbPhotoAsset).onAppear() {
                                if dbPhotoAsset.localIdentifier == databaseStream.lazyArray.sortedArray.last!.localIdentifier {
                                    databaseStream.addMoreToLazyArray()
                                }
                            }.matchedGeometryEffect(id: "thumbnailImageTransition" + dbPhotoAsset.localIdentifier, in: animation)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        self.selectedDbPhotoAsset = dbPhotoAsset
                                    }
                                }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
}

struct FullImageView: View {
    @Binding var selectedDbPhotoAsset: DBPhotoAsset?
    @ObservedObject var viewManager: ViewManager
    let currentDbPhotoAsset: DBPhotoAsset
    let animationId: Namespace.ID
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    @State private var viewOffset = CGSize.zero // To track the total offset
    @State private var dragOffset = CGSize.zero // To track the current drag
    let scalingFactor: CGFloat = 0.5
    
    init(selectedDbPhotoAsset: Binding<DBPhotoAsset?>, currentDbPhotoAsset: DBPhotoAsset, animationId: Namespace.ID) {
        self._selectedDbPhotoAsset = selectedDbPhotoAsset
        self.viewManager = ViewManager(dbAsset: currentDbPhotoAsset)
        self.currentDbPhotoAsset = currentDbPhotoAsset
        self.animationId = animationId
    }
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeOut) {
                    self.selectedDbPhotoAsset = nil
                }
            }) {
                Image(systemName: "arrowshape.backward.fill")
                    .padding()
            }
            if viewManager.view != nil {
                if #available(iOS 17.0, *) {
                    viewManager.view!
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
                                if abs(viewOffset.width) > 300 || abs(viewOffset.height) > 300 {
                                    withAnimation(.easeOut) {
                                        self.selectedDbPhotoAsset = nil
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
                    viewManager.view!
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .scaledToFit()
                        .scaleEffect(currentZoom + totalZoom)
                        .gesture(
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
            } else {
                Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: currentDbPhotoAsset.thumbnailFileName).path) ?? UIImage())
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
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
    @Published var view: AnyView?
    
    init(dbAsset: DBPhotoAsset) {
        self.dbAsset = dbAsset
    }
    
    func getView() async {
        if dbAsset.mediaSubtype.contains(.photoLive) {
            let livePhotoAssets = await FullSizeImageRetrieval.shared.getLiveImageResources(asset: dbAsset)
            if livePhotoAssets != nil {
                PHLivePhoto.request(withResourceFileURLs: [livePhotoAssets!.photoUrl, livePhotoAssets!.videoUrl], placeholderImage: nil, targetSize: CGSizeZero, contentMode: .aspectFit, resultHandler: { lPhoto, info in
                    DispatchQueue.main.async {
                        self.view = AnyView(UIKitLivePhotoView(livephoto: lPhoto))
                    }
                })
            }
        } else {
            // TODO: Detect image or video
            let photoAssets = await FullSizeImageRetrieval.shared.getImageResource(asset: dbAsset)
            if let img = photoAssets {
                do {
                    print(try FileManager.default.attributesOfItem(atPath: img.path))
                    print(try getSHA256(forFile: img))
                } catch {
                    print(error)
                }
                DispatchQueue.main.sync {
                    self.view = AnyView(
                        Image(uiImage: UIImage(contentsOfFile: img.path) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    )
                }
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

struct ThumbnailImage: View {
    let dbPhotoAsset: DBPhotoAsset
    @Binding var selectedDbPhotoAsset: DBPhotoAsset?
    
    var body: some View {
        Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName).path) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
            .aspectRatio(1, contentMode: .fit)
    }
}

//#Preview {
//    ContentView()
//}
