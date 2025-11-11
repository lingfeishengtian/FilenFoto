//
//  ChildPageTemplateViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import UIKit

class ChildPageTemplateViewController: PhotoGalleryTemplateViewController {
    let animationController: PhotoHeroAnimationController
    let image: FFDisplayableImage
    var imageId: PhotoIdentifier
    /// Purely for tagging purposes during transition
    
    required init(animationController: PhotoHeroAnimationController, image: FFDisplayableImage, imageId: PhotoIdentifier, photoGalleryContext: PhotoGalleryContext) {
        self.image = image
        self.imageId = imageId
        self.animationController = animationController
        
        super.init(photoGalleryContext: photoGalleryContext)
    }
    
    var pagingViewController: PagedPhotoDetailViewController {
        if let parent = self.parent?.parent as? PagedPhotoDetailViewController {
            return parent
        }
        
        fatalError("ChildPageTemplateViewController must be a child of PagedPhotoDetailViewController")
    }
    
    func setPageScroll(_ isEnabled: Bool) {
        for case let scrollView as UIScrollView in pagingViewController.pagedController.view.subviews {
            scrollView.isScrollEnabled = isEnabled
        }
    }
    
    override func commitLocalSelectedPhotoIndex() {
        pagingViewController.commitLocalSelectedPhotoIndex()
    }
}
