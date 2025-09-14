//
//  Types.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/7/25.
//

import Foundation

let MAX_THUMBNAILS_PER_FOLDER = 1000

struct ThumbnailIndex: RawRepresentable {
    let folderIndex: UInt32
    let thumbnailIndex: UInt32
    
    init(folderIndex: UInt32, thumbnailIndex: UInt32) {
        self.folderIndex = folderIndex
        self.thumbnailIndex = thumbnailIndex
    }
    
    init(rawValue: Int64) {
        self.folderIndex = UInt32((rawValue >> 32) & 0xFFFFFFFF)
        self.thumbnailIndex = UInt32(rawValue & 0xFFFFFFFF)
    }
    
    var rawValue: Int64 {
        let folderPart = Int64(folderIndex) << 32
        let thumbnailPart = Int64(thumbnailIndex) & 0xFFFFFFFF
        
        return folderPart | thumbnailPart
    }
    
    func incremented() -> ThumbnailIndex {
        if folderIndex == UInt32.max {
            // TODO: Handle overflow, but this is low priority
        }
        
        if thumbnailIndex >= MAX_THUMBNAILS_PER_FOLDER {
            return ThumbnailIndex(folderIndex: folderIndex + 1, thumbnailIndex: 0)
        }
        
        return ThumbnailIndex(folderIndex: folderIndex, thumbnailIndex: thumbnailIndex + 1)
    }
}
