//
//  FFDetailedPhotoViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

/// Parent class to other detailed photo view controllers that can be shown with `PagedPhotoViewerViewController`.
class FFParentImageViewController: UIViewController, PhotoContextDelegate, PagedPhotoHeroAnimatorDelegate {
    let image: UIImage?
    let animationController: PhotoHeroAnimationController
    let imageIndex: Int
    
    var imageView: UIImageView!
    /// Purely for tagging purposes during transition

    required init(animationController: PhotoHeroAnimationController, image: UIImage?, imageIndex: Int) {
        self.image = image
        self.animationController = animationController
        self.imageIndex = imageIndex

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func willUpdateSelectedPhotoIndex(_ index: Int) {
        // TODO: Implement in subclasses if needed
    }
    
    func getAnimationReferences(in view: UIView) -> AnimationReferences {
        return AnimationReferences(imageReference: self.imageView, frame: view.frame)
    }
    
    func getParentForHoisting() -> PagedPhotoDetailViewController {
        guard let parent = self.parent as? PagedPhotoDetailViewController else {
            fatalError("Cannot find parent PagedPhotoDetailViewController")
        }
        
        return parent
    }
}
