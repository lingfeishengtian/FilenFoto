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
        
        try? fetchResultsController.performFetch()
        
        pagedController.delegate = self
        pagedController.dataSource = self
        pagedController.setViewControllers(currentViewControllers(), direction: .forward, animated: false, completion: nil)
        pagedController.didMove(toParent: self)
    }

    override func willUpdateSelectedPhotoId(_ newId: PhotoIdentifier?) {
        super.willUpdateSelectedPhotoId(newId)

        pagedController.setViewControllers(currentViewControllers(with: newId), direction: .forward, animated: false)
    }

    func currentViewControllers(with newId: PhotoIdentifier? = nil) -> [UIViewController]? {
        guard let selectedId = newId ?? selectedPhotoId, let currentViewController = getViewController(at: selectedId) else {
            return nil
        }

        return [currentViewController]
    }

    func getViewController(at objectId: PhotoIdentifier) -> UIViewController? {
        return ScrollableImageViewController(
            animationController: animationController,
            image: photo(for: objectId), imageId: objectId,
            photoGalleryContext: photoGalleryContext)
    }

    func onPageChanged(to objectId: PhotoIdentifier) {}
}
