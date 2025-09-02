//
//  PagedPhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

/// Other classes inherit this class if they need a more detailed paged detail view controller
class PagedPhotoDetailViewController: PhotoGalleryTemplateViewController {
    var pagedController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var animationController: PhotoHeroAnimationController!

    init(animationController: PhotoHeroAnimationController, photoGalleryContext: PhotoGalleryContext) {
        self.animationController = animationController

        super.init(photoGalleryContext: photoGalleryContext)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(pagedController)
        view.addSubview(pagedController.view)

        pagedController.delegate = self
        pagedController.dataSource = self
        pagedController.setViewControllers(currentViewControllers(), direction: .forward, animated: false, completion: nil)
        pagedController.didMove(toParent: self)
    }

    override func willUpdateSelectedPhotoIndex(_ index: Int?) {
        super.willUpdateSelectedPhotoIndex(index)
        
        pagedController.setViewControllers(currentViewControllers(with: index), direction: .forward, animated: false)
    }

    func currentViewControllers(with newIndex: Int? = nil) -> [UIViewController]? {
        guard let selectedIndex = newIndex ?? selectedPhotoIndex(), let currentViewController = getViewController(at: selectedIndex) else {
            return nil
        }
        
        return [currentViewController]
    }

    func getViewController(at index: Int) -> UIViewController? {
        if index < 0 || index >= photoDataSource().numberOfPhotos() {
            return nil
        }

        return ScrollableImageViewController(
            animationController: animationController, image: photoDataSource().photoAt(index: index), imageIndex: index,
            photoGalleryContext: photoGalleryContext)
    }
}
