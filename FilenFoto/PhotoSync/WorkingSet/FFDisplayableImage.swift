//
//  FFDisplayableImage.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/5/25.
//

import Foundation
import UIKit
import os

protocol ViewWithImage: UIView {
    var image: UIImage? { get }
}

extension UIImageView: ViewWithImage {}

protocol FFDisplayableImage: ViewWithImage {
    var workingAsset: WorkingSetFotoAsset { get }
}

class FFImage: UIImageView, FFDisplayableImage {
    var workingAsset: WorkingSetFotoAsset
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "FFImage")
    
    init(workingAsset: WorkingSetFotoAsset, thumbnail: UIImage?) {
        self.workingAsset = workingAsset
        super.init(image: thumbnail)
        
        Task.detached(priority: .background) {
            guard let imageResource = try? await workingAsset.resource(for: .photo, cancellable: true), let uiImage = UIImage(contentsOfFile: imageResource.path()) else {
                return
            }
            
            // Load full size image contents from background thread so main thread doesnt freeze
            uiImage.prepareForDisplay { [weak self] loadedImage in
                Task { @MainActor in
                    self?.image = loadedImage
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
