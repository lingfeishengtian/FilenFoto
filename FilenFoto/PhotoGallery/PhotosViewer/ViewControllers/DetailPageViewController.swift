//
//  PagedPhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

class DetailPageViewController: PagedPhotoDetailViewController {
    override func getViewController(at index: Int) -> UIViewController? {
        if index < 0 || index >= countOfPhotos {
            return nil
        }

        return DetailedPhotoViewController(
            animationController: animationController, image: photo(at: index), imageIndex: index, photoGalleryContext: photoGalleryContext)
    }
}
