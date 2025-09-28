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
        DetailedPhotoViewController(
            animationController: animationController, image: photo(for: objectId), imageId: objectId, photoGalleryContext: photoGalleryContext)
    }
}
