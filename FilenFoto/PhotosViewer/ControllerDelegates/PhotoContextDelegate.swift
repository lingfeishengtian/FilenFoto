//
//  PhotoDataDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FilenFoto", category: "PhotoContextDelegate")

protocol PhotoContextDelegate: UIViewController {
    func willUpdateSelectedPhotoIndex(_ index: Int)
}

protocol PhotoContextHost: AnyObject, PhotoContextDelegate {
    var selectedPhotoIndex: Int? { get set }
    var photoDataSource: PhotoDataSourceProtocol? { get set }
    var detailedPhotoViewBuilder: DetailedPhotoViewBuilder? { get set }
}

/// This is over-engineered, but is a concept of how we can state manager across the navigationController
extension PhotoContextDelegate {
    fileprivate func findContextHostIndex() -> PhotoContextHost? {
        return navigationController?
            .viewControllers
            .reversed()
            .first { $0 is PhotoContextHost  } as? PhotoContextHost
    }
    
    func getDetailedPhotoBuilder() -> DetailedPhotoViewBuilder? {
        return findContextHostIndex()?.detailedPhotoViewBuilder
    }
    
    /// More efficient than getPhotoDataSource + getSelectedPhotoIndex
    func selectedPhoto() -> UIImage? {
        guard let host = findContextHostIndex(), let at = host.selectedPhotoIndex else {
            logger.error("No PhotoContextHost or selectedPhotoIndex found in navigation stack.")
            return nil
        }
        
        return host.photoDataSource?.photoAt(index: at)
    }
    
    /// Looks for, from top to bottom, the first view that conforms to PhotoContextHost and returns its photoDataSource
    func getPhotoDataSource() -> PhotoDataSourceProtocol? {
        let photoDataSource = findContextHostIndex()?.photoDataSource
        
        if photoDataSource == nil {
            logger.error("No PhotoDataSource found in navigation stack.")
        }
        
        return photoDataSource
    }
    
    /// Looks for, from top to bottom, the first view that conforms to PhotoContextHost
    func getSelectedPhotoIndex() -> Int? {
        return findContextHostIndex()?.selectedPhotoIndex
    }
    
    /// Looks for, first, the context host starting from the top of the stack, then sets the selected photo index and calls updateSelectedPhotoIndex on all views following it in the navigation stack as they should all conform to `PhotoContextDelegate`, if they do not, warn in the log.
    /// Will not call `willUpdateSelectedPhotoIndex` on the caller of the this function
    func setSelectedPhotoIndex(_ index: Int) {
        let viewControllers = self.navigationController?.viewControllers ?? []
        
        guard let hostIndex = viewControllers.lastIndex(where: { $0 is PhotoContextHost }) else {
            logger.warning("No PhotoContextHost found in navigation stack.")
            return
        }
        
        (viewControllers[hostIndex] as? PhotoContextHost)?.selectedPhotoIndex = index
        
        for vc in viewControllers[hostIndex...] {
            if let contextDelegate = vc as? PhotoContextDelegate {
                if contextDelegate != self {
                    contextDelegate.willUpdateSelectedPhotoIndex(index)
                }
            } else {
                logger.warning("ViewController \(String(describing: vc)) does not conform to PhotoContextDelegate.")
            }
        }
    }
}
