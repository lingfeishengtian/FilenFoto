//
//  PhotoDetailViewController+AnimationDelegates.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import AVKit
import Foundation
import UIKit

extension PhotoDetailViewController: PhotoHeroAnimatorDelegate {
    func getAnimationReferences() -> AnimationReferences {
        guard let image = self.imageView.image else {
            return AnimationReferences(imageReference: self.imageView, frame: self.imageView.frame)
        }

        let actualImageFrame = AVMakeRect(aspectRatio: image.size, insideRect: self.imageView.bounds)

        return AnimationReferences(imageReference: self.imageView, frame: actualImageFrame)
    }
}
