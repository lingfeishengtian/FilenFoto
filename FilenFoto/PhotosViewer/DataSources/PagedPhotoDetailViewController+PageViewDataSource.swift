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
        guard let selectedIndex = self.getSelectedPhotoIndex(), let dataSource = self.getPhotoDataSource() else {
            return nil
        }
        
        let previousIndex = selectedIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        
        let previousPhoto = dataSource.photoAt(index: previousIndex)
        let previousVC = PageType.init(animationController: animationController, image: previousPhoto, imageIndex: previousIndex)
        
        return previousVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let selectedIndex = self.getSelectedPhotoIndex(), let dataSource = self.getPhotoDataSource() else {
            return nil
        }
        
        let nextIndex = selectedIndex + 1
        guard nextIndex < dataSource.numberOfPhotos() else {
            return nil
        }
        
        let nextPhoto = dataSource.photoAt(index: nextIndex)
        let nextVC = PageType.init(animationController: animationController, image: nextPhoto, imageIndex: nextIndex)
        
        return nextVC
    }
}
