//
//  ThumbnailProvider.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/6/25.
//

import Foundation
import Photos

class ThumbnailProvider: PhotoActionProviderDelegate {
    private init() {}
    static let shared = ThumbnailProvider()
    
    func initiateProtocol(for photo: PHAsset, with identifier: UUID) async -> Bool {
        print("Initiate ThumbnailProvider for photo with identifier: \(identifier)")
        let numSeconds = UInt64.random(in: 1...5)
        print("Will take \(numSeconds) seconds to complete")
        try? await Task.sleep(nanoseconds: numSeconds * 1_000_000_000)
        
        return true
    }
}
