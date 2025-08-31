//
//  PagedPhotoDetailViewController+PageViewDataSource.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

extension PagedPhotoDetailViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = (viewController as? ChildPageProtocol)?.imageIndex else {
            return nil
        }
        
        let previousIndex = currentIndex - 1
        return getViewController(at: previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = (viewController as? ChildPageProtocol)?.imageIndex else {
            return nil
        }
        
        let nextIndex = currentIndex + 1
        return getViewController(at: nextIndex)
    }
}
