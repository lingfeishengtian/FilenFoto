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
        guard let currentId = (viewController as? ChildPageTemplateViewController)?.imageId else {
            return nil
        }
        
        guard let selectedIndexPath else {
            return nil
        }
        
        let indexBefore = selectedIndexPath.row - 1
        if indexBefore < 0 {
            return nil
        }
        
        let idAtIndexBefore = fetchResultsController.object(at: IndexPath(row: indexBefore, section: selectedIndexPath.section)).objectID
        return getViewController(at: idAtIndexBefore)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentId = (viewController as? ChildPageTemplateViewController)?.imageId else {
            return nil
        }
        
        guard let selectedIndexPath else {
            return nil
        }
        
        let indexAfter = selectedIndexPath.row + 1
        if indexAfter >= countOfPhotos {
            return nil
        }
        
        let idAtIndexAfter = fetchResultsController.object(at: IndexPath(row: indexAfter, section: selectedIndexPath.section)).objectID
        return getViewController(at: idAtIndexAfter)
    }
}
