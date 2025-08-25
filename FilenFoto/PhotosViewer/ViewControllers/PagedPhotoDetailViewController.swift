//
//  PagedPhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

class PagedPhotoDetailViewController: UIViewController, PhotoContextDelegate {
    var PageType: FFParentImageViewController.Type!

    var pagedController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var animationController: PhotoHeroAnimationController!

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(pagedController)
        view.addSubview(pagedController.view)

        pagedController.delegate = self
        pagedController.dataSource = self

        let initialPhotoVC = PageType.init(
            animationController: animationController, image: selectedPhoto(), imageIndex: getSelectedPhotoIndex() ?? 0)

        pagedController.setViewControllers([initialPhotoVC], direction: .forward, animated: false, completion: nil)
        pagedController.didMove(toParent: self)
    }

    func willUpdateSelectedPhotoIndex(_ index: Int) {
        // TODO: Implement this method to update the page view controller to the new index
        // TODO: Call update on pageController's 3 view controllers
    }
}
