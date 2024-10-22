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
    @Binding private var assetFileUrl: URL?
    
    let onSwipeUp: (() -> Void)
    let onSwipeDown: (() -> Void)
    
    @Binding var isScrolling: Bool
    
    init(scale: Binding<CGFloat>, offset: Binding<CGSize>, onSwipeUp: @escaping () -> Void = {}, isScrolling: Binding<Bool>, onSwipeDown: @escaping () -> Void = {}, assetFileUrl: Binding<URL?>) {
        self._scale = scale
        self._offset = offset
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self._isScrolling = isScrolling
        self._assetFileUrl = assetFileUrl
    }
    
    func setView(_ view: some View) {
        DispatchQueue.main.async {
            withAnimation {
                self.view = AnyView(view)
            }
        }
    }
    
    @State var curTask: Task<Void, Never>? = nil
    
    var body: some View {
        var imgPath: String? = nil
        var uiImage: UIImage? = nil
        
        if let dbAsset = photoEnviorment.selectedDbPhotoAsset {
            imgPath = PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbAsset.thumbnailFileName).path
            
#if targetEnvironment(simulator)
        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
//            print("Building \(dbAsset.localIdentifier)")
            let randomColors = [
                UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.orange,
                UIColor.purple, UIColor.cyan, UIColor.magenta,
            ]
            uiImage = dbAsset.localIdentifier.image(withAttributes: [
                .foregroundColor: UIColor.red,
                .font: UIFont.systemFont(ofSize: 10.0),
                .backgroundColor: randomColors.randomElement()!,
            ])
        }
#endif
        }
        
        return VStack {
            (self.view ?? AnyView(ZoomablePhoto(
                scale: $scale,
                offset: $offset,
                onSwipeUp: onSwipeUp,
                onSwipeDown: onSwipeDown,
                image: .constant(uiImage ?? (imgPath != nil ? (UIImage(contentsOfFile: imgPath!) ?? UIImage()) : UIImage())))
                .overlay {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView().progressViewStyle(.circular)
                                .scaleEffect(1.5)
                        )
                        .allowsHitTesting(false)
                }))
            .scaleEffect(scale)
            .offset(offset)
            .onChange(of: isScrolling) {
                if !isScrolling {
                    isScrolling = true
                    self.view = nil
                    self.assetFileUrl = nil
                    curTask?.cancel()
                    curTask = Task {
                        await getView()
                    }
                }
            }.onChange(of: photoEnviorment.selectedDbPhotoAsset) {
                self.view = nil
                self.assetFileUrl = nil
            }
//            }
        }
        //        }.scaleEffect(scale)
//        .offset(offset)
    }
    
    func getView() async {
        guard let dbAsset = photoEnviorment.selectedDbPhotoAsset else {
            return
        }
//        let imgPath = FullSizeImageCache.getFullSizeImageOrThumbnail(for: photoEnviorment.selectedDbPhotoAsset!).path

        if dbAsset.mediaType == .image {
            if dbAsset.mediaSubtype.contains(.photoLive) {
                let livePhotoAssets = await FullSizeImageRetrieval.shared.getLiveImageResources(asset: dbAsset)
                if livePhotoAssets != nil {
                    PHLivePhoto.request(withResourceFileURLs: [livePhotoAssets!.photoUrl, livePhotoAssets!.videoUrl], placeholderImage: nil, targetSize: CGSizeZero, contentMode: .aspectFit, resultHandler: { lPhoto, info in
//                        self.setView(AnyView(UIKitLivePhotoView(livephoto: lPhoto)))
                        self.assetFileUrl = livePhotoAssets?.photoUrl
                        if let lPhoto {
                            DispatchQueue.main.async {
                                self.setView(ZoomableLivePhoto(
                                    scale: self.$scale,
                                    offset: self.$offset,
                                    onSwipeUp: self.onSwipeUp,
                                    onSwipeDown: self.onSwipeDown,
                                    livePhoto: .constant(lPhoto)))
                            }
                        }
                    })
                }
            } else {
                let photoAssets = await FullSizeImageRetrieval.shared.getImageResource(asset: dbAsset)
                self.assetFileUrl = photoAssets
                if let img = photoAssets {
                    setView(AnyView(
                        ZoomablePhoto(
                        scale: $scale,
                        offset: $offset,
                        onSwipeUp: onSwipeUp,
                        onSwipeDown: onSwipeDown,
                        image: .constant(UIImage(contentsOfFile: img.path) ?? UIImage()))
                    ))
                }
            }
        } else if dbAsset.mediaType == .video {
            let videoAssets = await FullSizeImageRetrieval.shared.getVideoResource(asset: dbAsset)
            self.assetFileUrl = videoAssets
            if let vid = videoAssets {
                setView(AnyView(ZoomableVideo(
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
//    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    let thumbnailName: String
    
    var body: some View {
//#if targetEnvironment(simulator)
//        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
////            print("Building \(dbPhotoAsset.localIdentifier)")
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
////            print("building \(dbPhotoAsset.localIdentifier)")
//        }
//#endif
        
//        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
//            .resizable()
//            .scaledToFill()
//        )
//        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
////        return Color.clear.background(AsyncImage(url: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName))
//            .resizable()
//                    .scaledToFill()
//                )
        return Image(uiImage: (UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailName).path) ?? UIImage()))
//        return Color.clear.background(AsyncImage(url: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName))
            .resizable()
            .scaledToFill()
        .aspectRatio(1, contentMode: .fit)
        .clipped()
//        .contentShape(Rectangle())
//        .onAppear() {
//            Task {
////                if dbPhotoAsset.localIdentifier == photoEnvironment.lazyArray.sortedArray.last?.localIdentifier {
////                    await photoEnvironment.addMoreToLazyArray()
////                }
//            }
//        }
//        .onTapGesture {
//            withAnimation {
//                photoEnvironment.firstSelected = dbPhotoAsset
//                photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
//            }
//        }
    }
}
