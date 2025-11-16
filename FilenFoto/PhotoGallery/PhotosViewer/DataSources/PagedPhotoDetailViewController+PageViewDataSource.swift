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
        guard let currentObjectId = (viewController as? ChildPageTemplateViewController)?.imageId,
            let currentIndexPath = indexPath(for: currentObjectId)
        else {
            return nil
        }

        let indexBefore = currentIndexPath.row - 1
        if indexBefore < 0 {
            return nil
        }
        
        let prevIndexPath = IndexPath(row: indexBefore, section: currentIndexPath.section)
        let prevIndexObjectId = typedID(fotoAsset(at: prevIndexPath))
        return getViewController(at: prevIndexObjectId)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentObjectId = (viewController as? ChildPageTemplateViewController)?.imageId,
            let currentIndexPath = indexPath(for: currentObjectId)
        else {
            return nil
        }

        let indexAfter = currentIndexPath.row + 1
        // TODO: I imagine this might generate a bug where count of photos hasn't updated yet?
        if indexAfter >= countOfPhotos {
            return nil
        }
        
        let nextIndexPath = IndexPath(row: indexAfter, section: currentIndexPath.section)
        let nextIndexObjectId = typedID(fotoAsset(at: nextIndexPath))
        return getViewController(at: nextIndexObjectId)
    }
}
