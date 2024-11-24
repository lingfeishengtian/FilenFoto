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
    private var imageViewType: ImageViewType
    private var assetId: Int64? = nil
    
    /// Asset should either be a UIImage, PHLivePhoto, AVPlayer, or URL to an Image
    /// Should not be modified by any other file due to this being quite unsafe
    fileprivate init(asset: Any? = nil, imageViewType: ImageViewType = .image, assetId: Int64? = nil) {
        self.storedAssetView = asset
        self.imageViewType = imageViewType
        self.assetId = assetId
    }
    
    func isLoaded(dbPhotoAsset: DBPhotoAsset?) -> Bool {
        storedAssetView != nil && dbPhotoAsset != nil && assetId == dbPhotoAsset?.id
    }
    
    func generateView(dbPhotoAsset: DBPhotoAsset?, isPinching: Binding<Bool>) -> AnyView {
        var asset = storedAssetView
        if assetId != dbPhotoAsset?.id {
            asset = nil
        }
        switch asset {
        case let livePhoto as PHLivePhoto:
            return AnyView(
                ZoomableLivePhoto(
                    isPinching: isPinching,
                    livePhoto: .constant(livePhoto)))
        case let assetURL as URL:
            switch imageViewType {
            case .image:
                return AnyView(
                    ZoomableImage(
                        isPinching: isPinching,
                        imageURL: assetURL))
            case .video:
                return AnyView(
                    ZoomableVideo(
                        isPinching: isPinching,
                        videoURL: assetURL))
            default:
                return AnyView(EmptyView())
            }
        default:
            let imageURL: URL
            if let url = asset as? URL, isLoaded(dbPhotoAsset: dbPhotoAsset) {
                imageURL = url
            } else if let dbPhotoAsset {
                imageURL = dbPhotoAsset.thumbnailURL
            } else {
                return AnyView(EmptyView())
            }
            return AnyView(
                ZoomableImage(
                    isPinching: isPinching,
                    imageURL: imageURL))
        }
    }
}

class FullImageViewState: ObservableObject {
    @Published var isPinching = false
    let dismissThreshold: CGFloat = 600
    
    @Published var showDetail: Bool = false
    @Published var imageViewGeneration: ImageViewGenerationData = .init()
    
    @Published var showBurstImages: Bool = false
    
    var assetFileUrl: URL?
    var shouldHideBars: Bool {
        isPinching || showDetail
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
                    self.imageViewGeneration = .init(asset: vid, imageViewType: .video, assetId: dbAsset.id)
                }
            }
        }
    }
}
