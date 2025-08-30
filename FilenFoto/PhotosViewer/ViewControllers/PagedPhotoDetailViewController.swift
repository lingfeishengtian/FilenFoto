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
        pagedController.setViewControllers(generateCurrentViewControllers(), direction: .forward, animated: false, completion: nil)
        pagedController.didMove(toParent: self)
    }

    func willUpdateSelectedPhotoIndex(_ index: Int) {
        pagedController.setViewControllers(generateCurrentViewControllers(), direction: .forward, animated: false)
    }
    
    fileprivate func generateCurrentViewControllers() -> [UIViewController]? {
        guard let selectedPhotoIndex = selectedPhotoIndex() else {
            return nil
        }
        
        return [PageType.init(
            animationController: animationController, image: selectedPhoto(), imageIndex: selectedPhotoIndex)]
    }
}
