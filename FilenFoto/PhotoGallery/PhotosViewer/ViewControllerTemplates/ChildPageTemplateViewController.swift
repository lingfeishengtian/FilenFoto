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
    let image: UIImage?
    var imageIndex: Int
    /// Purely for tagging purposes during transition
    
    required init(animationController: PhotoHeroAnimationController, image: UIImage?, imageIndex: Int, photoGalleryContext: PhotoGalleryContext) {
        self.image = image
        self.imageIndex = imageIndex
        self.animationController = animationController
        
        super.init(photoGalleryContext: photoGalleryContext)
    }
    
    var pagingViewController: PagedPhotoDetailViewController {
        if let parent = self.parent?.parent as? PagedPhotoDetailViewController {
            return parent
        }
        
        fatalError("ChildPageTemplateViewController must be a child of PagedPhotoDetailViewController")
    }
    
    override func commitLocalSelectedPhotoIndex() {
        pagingViewController.commitLocalSelectedPhotoIndex()
    }
}
