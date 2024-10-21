//
//  HelperImagerViews.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI
import PhotosUI
import AVKit

enum TypeOfView {
    case image
    case livePhoto
    case video
}

struct ViewManager: View {
    @EnvironmentObject var photoEnviorment: PhotoEnvironment
    @State private var view: AnyView? = nil
    
    @Binding private var scale: CGFloat
    @Binding private var offset: CGSize
    
    let onSwipeUp: (() -> Void)
    let onSwipeDown: (() -> Void)
    
    init(scale: Binding<CGFloat>, offset: Binding<CGSize>, onSwipeUp: @escaping () -> Void = {}, onSwipeDown: @escaping () -> Void = {}) {
//        let imgPath = FullSizeImageCache.getFullSizeImageOrThumbnail(for: photoEnviorment.selectedDbPhotoAsset!).path
//        
//#if targetEnvironment(simulator)
//        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
//            self.view = AnyView(
//                ZoomablePhoto(
//                    scale: scale,
//                    offset: offset,
//                    onSwipeUp: onSwipeUp,
//                    onSwipeDown: onSwipeDown,
//                    image: UIImage.init(named: "IMG_3284")!)
//                )
//        } else {
//            self.view = AnyView(
//                ZoomablePhoto(
//                    scale: scale,
//                    offset: offset,
//                    onSwipeUp: onSwipeUp,
//                    onSwipeDown: onSwipeDown,
//                    image: UIImage(contentsOfFile: imgPath) ?? UIImage()))
//        }
//#else
//        self.view = AnyView(
//            ZoomablePhoto(
//                scale: scale,
//                offset: offset,
//                onSwipeUp: onSwipeUp,
//                onSwipeDown: onSwipeDown,
//                image: UIImage(contentsOfFile: imgPath) ?? UIImage()))
//#endif
        self._scale = scale
        self._offset = offset
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
    }
    
    func setView(_ view: some View) {
        DispatchQueue.main.async {
            withAnimation {
                self.view = AnyView(view)
            }
        }
    }
    
    var body: some View {
        
        var imgPath: String? = nil
        if let dbAsset = photoEnviorment.selectedDbPhotoAsset {
            imgPath = FullSizeImageCache.getFullSizeImageOrThumbnail(for: dbAsset).path
        }
        

        return VStack {
            if let imgPath, photoEnviorment.selectedDbPhotoAsset!.mediaType == .image {
                ZoomablePhoto(
                    scale: $scale,
                    offset: $offset,
                    onSwipeUp: onSwipeUp,
                    onSwipeDown: onSwipeDown,
                    image: .constant(UIImage(contentsOfFile: imgPath) ?? UIImage()))
                    .scaleEffect(scale)
                    .offset(offset)
            } else {
                self.view
                        .scaleEffect(scale)
                        .offset(offset)
            }
        }
//        view.onAppear {
//            Task {
////                await getView()
//            }
//        }.scaleEffect(scale)
//        .offset(offset)
    }
    
    func getView() async {
        let dbAsset = photoEnviorment.selectedDbPhotoAsset!
        let imgPath = FullSizeImageCache.getFullSizeImageOrThumbnail(for: photoEnviorment.selectedDbPhotoAsset!).path

        if dbAsset.mediaType == .image {
            if dbAsset.mediaSubtype.contains(.photoLive) {
                let livePhotoAssets = await FullSizeImageRetrieval.shared.getLiveImageResources(asset: dbAsset)
                if livePhotoAssets != nil {
                    PHLivePhoto.request(withResourceFileURLs: [livePhotoAssets!.photoUrl, livePhotoAssets!.videoUrl], placeholderImage: nil, targetSize: CGSizeZero, contentMode: .aspectFit, resultHandler: { lPhoto, info in
//                        self.setView(AnyView(UIKitLivePhotoView(livephoto: lPhoto)))
                        if let lPhoto {
                            DispatchQueue.main.async {
                                self.setView(ZoomableLivePhoto(
                                    scale: self.$scale,
                                    offset: self.$offset,
                                    onSwipeUp: self.onSwipeUp,
                                    onSwipeDown: self.onSwipeDown,
                                    livePhoto: lPhoto))
                            }
                        }
                    })
                }
            } else {
                let photoAssets = await FullSizeImageRetrieval.shared.getImageResource(asset: dbAsset)
                if let img = photoAssets, imgPath != img.path {
//                    setView(AnyView(ZoomablePhoto(
//                        scale: $scale,
//                        offset: $offset,
//                        onSwipeUp: onSwipeUp,
//                        onSwipeDown: onSwipeDown,
//                        image: UIImage(contentsOfFile: img.path) ?? UIImage()))
//                    )
                }
            }
        } else if dbAsset.mediaType == .video {
            let videoAssets = await FullSizeImageRetrieval.shared.getVideoResource(asset: dbAsset)
            if let vid = videoAssets {
                await setView(AnyView(ZoomableVideo(
                    scale: $scale,
                    offset: $offset,
                    onSwipeUp: onSwipeUp,
                    onSwipeDown: onSwipeDown,
                    video: AVPlayer(url: vid)))
                )
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

struct ThumbnailView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    let dbPhotoAsset: DBPhotoAsset
    
    init(dbPhotoAsset: DBPhotoAsset) {
        self.dbPhotoAsset = dbPhotoAsset
    }
    
    var body: some View {
        var uiImage = UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName).path)
//#if targetEnvironment(simulator)
//        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
//            print("Building \(dbPhotoAsset.localIdentifier)")
//            let randomColors = [
//                UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.orange,
//                UIColor.purple, UIColor.cyan, UIColor.magenta,
//            ]
//            uiImage = dbPhotoAsset.localIdentifier.image(withAttributes: [
//                .foregroundColor: UIColor.red,
//                .font: UIFont.systemFont(ofSize: 10.0),
//                .backgroundColor: randomColors.randomElement()!,
//            ])
//        } else {
//            print("building \(dbPhotoAsset.localIdentifier)")
//        }
//#endif
        
//        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
//            .resizable()
//            .scaledToFill()
//        )
        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
//        return Color.clear.background(AsyncImage(url: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName))
            .resizable()
                    .scaledToFill()
                )
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
        .onAppear() {
            Task {
//                if dbPhotoAsset.localIdentifier == photoEnvironment.lazyArray.sortedArray.last?.localIdentifier {
//                    await photoEnvironment.addMoreToLazyArray()
//                }
            }
        }
        .onTapGesture {
            withAnimation {
                photoEnvironment.firstSelected = dbPhotoAsset
                photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
            }
        }
    }
}
