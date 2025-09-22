//
//  FFAssetManager+Cache.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation
import Photos

enum DisplayImageType {
    case standardImage
    case livePhoto
    case standardVideo
    case audio
    case unknown
}

extension FotoAsset {
    var displayImageType: DisplayImageType {
        if mediaType == .image {
            if mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            
            return .standardImage
        }
        
        if mediaType == .video {
            return .standardVideo
        }
        
        if mediaType == .audio {
            return .audio
        }
        
        return .unknown
    }
}
