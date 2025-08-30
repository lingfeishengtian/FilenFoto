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

/// This is over-engineered, but is a concept of how we can state manager across the navigationController
extension PhotoContextDelegate {
    fileprivate func getPhotoContext() -> PhotoContextNavigationController {
        guard let host = self.navigationController as? PhotoContextNavigationController else {
            fatalError("PhotoContextDelegates are only supported in PhotoContextNavigationControllers")
        }
        
        return host
    }
    
    /// More efficient than getPhotoDataSource + getSelectedPhotoIndex
    func selectedPhoto() -> UIImage? {
        let host = getPhotoContext()
        
        guard let index = host.selectedPhotoIndex else {
            logger.error("Tried to access selected photo but no index was set")
            return nil
        }
        
        return host.photoDataSource.photoAt(index: index)
    }
    
    func photoDataSource() -> PhotoDataSourceProtocol {
        getPhotoContext().photoDataSource
    }
    
    func swiftUIProvider() -> SwiftUIProviderProtocol {
        getPhotoContext().swiftUIProvider
    }
    
    func selectedPhotoIndex() -> Int? {
        return getPhotoContext().selectedPhotoIndex
    }
    
    // TODO: Write docs
    func setSelectedPhotoIndex(_ index: Int) {
        getPhotoContext().selectedPhotoIndex = index
        
        let viewControllers = self.navigationController?.viewControllers ?? []
        
        for case let viewController as PhotoContextDelegate in viewControllers {
            if viewController == self || self.view.isDescendant(of: viewController.view) {
                continue
            }
            
            viewController.willUpdateSelectedPhotoIndex(index)
        }
    }
}
