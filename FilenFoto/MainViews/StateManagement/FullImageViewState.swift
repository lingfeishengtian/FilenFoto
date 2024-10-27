//
//  FullImageViewState.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/23/24.
//

import SwiftUI
import Photos

enum ImageViewType {
    case image
    case livePhoto
    case video
}

struct ImageViewGenerationData {
    private var storedAssetView: Any? = nil
    private var assetId: Int64? = nil
    
    /// Asset should either be a UIImage, PHLivePhoto, AVPlayer, or URL to an Image
    /// Should not be modified by any other file due to this being quite unsafe
    fileprivate init(asset: Any? = nil, assetId: Int64? = nil) {
        self.storedAssetView = asset
        self.assetId = assetId
    }
    
    func isLoaded(dbPhotoAsset: DBPhotoAsset?) -> Bool {
        storedAssetView != nil && dbPhotoAsset != nil && assetId == dbPhotoAsset?.id
    }
    
    func generateView(dbPhotoAsset: DBPhotoAsset?, scale: Binding<CGFloat>, offset: Binding<CGSize>, scrolling: Binding<Bool>, onSwipeUp: @escaping () -> Void, onSwipeDown: @escaping () -> Void) -> AnyView {
#if targetEnvironment(simulator)
        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
            return AnyView(ZoomablePhoto(
                scale: scale,
                offset: offset,
                scrolling: scrolling,
                onSwipeUp: onSwipeUp,
                onSwipeDown: onSwipeDown,
                image: .constant(UIImage(named: "IMG_3284")!)))
        }
#endif
        var asset = storedAssetView
        if assetId != dbPhotoAsset?.id {
            asset = nil
        }
        switch asset {
        case let uiImage as UIImage:
            return AnyView(
                ZoomablePhoto(
                    scale: scale,
                    offset: offset,
                    scrolling: scrolling,
                    onSwipeUp: onSwipeUp,
                    onSwipeDown: onSwipeDown,
                    image: .constant(uiImage)))
        case let livePhoto as PHLivePhoto:
            return AnyView(
                ZoomableLivePhoto(
                    scale: scale,
                    offset: offset,
                    scrolling: scrolling,
                    onSwipeUp: onSwipeUp,
                    onSwipeDown: onSwipeDown,
                    livePhoto: .constant(livePhoto)))
        case let avPlayer as AVPlayer:
            return AnyView(ZoomableVideo(
                scale: scale,
                offset: offset,
                scrolling: scrolling,
                onSwipeUp: onSwipeUp,
                onSwipeDown: onSwipeDown,
                video: avPlayer))
        default:
            var uiImage = UIImage()
            if let dbPhotoAsset, let image = UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) {
                uiImage = image
            }
            if let url = asset as? URL, let image = UIImage(contentsOfFile: url.path) {
                uiImage = image
            }
            return AnyView(
                ZoomablePhoto(
                    scale: scale,
                    offset: offset,
                    scrolling: scrolling,
                    onSwipeUp: onSwipeUp,
                    onSwipeDown: onSwipeDown,
                    image: .constant(uiImage)))
        }
    }
}

class FullImageViewState: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var scrolling: Bool = false
    //    @Published var sheetOffset: CGSize = .zero
    @Published private var isDragging = false
    let dismissThreshold: CGFloat = 600
    
    @Published var showDetail: Bool = false
    @Published var imageViewGeneration: ImageViewGenerationData = .init()
    
    @Published var showBurstImages: Bool = false
    
    var assetFileUrl: URL?
    
    var hasUserStoppedScrolling: Bool {
        !scrolling
    }
    
    var shouldHideBars: Bool {
        scrolling || showDetail || scale != 1.0
    }
    
    var adjustedScale: CGFloat {
        var scale_calculation = scale
        //  == 1.0 ? (offset.height < 0 ? (1.0 + (abs(offset.height) / 400)) : (1.0 - (abs(offset.height) / 400))) : scale
        
        if scale == 1.0 {
            if offset.height < 0 {
                scale_calculation = 1.0 + (abs(offset.height) / 400)
            } else {
                scale_calculation = 1.0 - (abs(offset.height) / 400)
            }
        }
        
        if scale_calculation < 0.8 {
            scale_calculation = 0.8
        }
        return scale_calculation
    }
    
    var curTask: Task<Void, Never>? = nil
    
    func getView(selectedDbPhotoAsset: DBPhotoAsset?) async {
        guard let dbAsset = selectedDbPhotoAsset else {
            return
        }
        
        if dbAsset.mediaType == .image {
            if dbAsset.mediaSubtype.contains(.photoLive) {
                let livePhotoAssets = await FullSizeImageRetrieval.shared.getLiveImageResources(asset: dbAsset)
                if livePhotoAssets != nil {
                    PHLivePhoto.request(withResourceFileURLs: [livePhotoAssets!.photoUrl, livePhotoAssets!.videoUrl], placeholderImage: nil, targetSize: CGSizeZero, contentMode: .aspectFit, resultHandler: { lPhoto, info in
                        self.assetFileUrl = livePhotoAssets?.photoUrl
                        if let lPhoto {
                            DispatchQueue.main.async {
                                self.imageViewGeneration = .init(asset: lPhoto, assetId: dbAsset.id)
                            }
                        }
                    })
                }
            } else {
                let photoAssets = await FullSizeImageRetrieval.shared.getImageResource(asset: dbAsset)
                assetFileUrl = photoAssets
                if let img = photoAssets {
                    DispatchQueue.main.async {
                        self.imageViewGeneration = .init(asset: img, assetId: dbAsset.id)
                    }
                }
            }
        } else if dbAsset.mediaType == .video {
            let videoAssets = await FullSizeImageRetrieval.shared.getVideoResource(asset: dbAsset)
            assetFileUrl = videoAssets
            if let vid = videoAssets {
                DispatchQueue.main.async {
                    self.imageViewGeneration = .init(asset: AVPlayer(url: vid), assetId: dbAsset.id)
                }
            }
        }
    }
}
