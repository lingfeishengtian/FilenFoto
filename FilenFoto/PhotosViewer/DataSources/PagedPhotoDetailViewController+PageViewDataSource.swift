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
        guard let selectedIndex = selectedPhotoIndex() else {
            return nil
        }
        
        let previousIndex = selectedIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        
        let previousPhoto = photoDataSource().photoAt(index: previousIndex)
        let previousVC = PageType.init(animationController: animationController, image: previousPhoto, imageIndex: previousIndex)
        
        return previousVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let selectedIndex = selectedPhotoIndex() else {
            return nil
        }
        
        let nextIndex = selectedIndex + 1
        guard nextIndex < photoDataSource().numberOfPhotos() else {
            return nil
        }
        
        let nextPhoto = photoDataSource().photoAt(index: nextIndex)
        let nextVC = PageType.init(animationController: animationController, image: nextPhoto, imageIndex: nextIndex)
        
        return nextVC
    }
}
