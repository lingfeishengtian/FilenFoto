//
//  PagedPhotoDetailView+PageDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

extension PagedPhotoDetailViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentPage = pageViewController.viewControllers?.first as? ChildPageTemplateViewController else {
            return
        }
        
        setSelectedPhotoIndex(currentPage.imageIndex)
        onPageChanged(to: currentPage.imageIndex)
    }
}

