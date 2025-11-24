//
//  PagedPhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

extension PagedPhotoDetailViewController: PhotoHeroAnimatorDelegate {
    func getAnimationReferences() -> AnimationReferences {
        guard let photoDetailViewController = self.pagedController.viewControllers?.first as? PagedPhotoHeroAnimatorDelegate else {
            return AnimationReferences(size: self.view.bounds.size)
        }
        
        return photoDetailViewController.getAnimationReferences(in: self.view)
    }
}

