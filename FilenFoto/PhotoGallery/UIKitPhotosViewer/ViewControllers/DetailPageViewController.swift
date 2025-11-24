//
//  PagedPhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

class DetailPageViewController: PagedPhotoDetailViewController {
    override func getViewController(at objectId: PhotoIdentifier) -> UIViewController? {
        guard let image = photo(for: objectId) else {
            return nil
        }
        
        return DetailedPhotoViewController(
            animationController: animationController, image: image, imageId: objectId, photoGalleryContext: photoGalleryContext)
    }
}
