//
//  PhotoDataDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import Combine
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FilenFoto", category: "PhotoContextDelegate")

protocol PhotoContextDelegate: UIViewController {
    var photoGalleryContext: PhotoGalleryContext { get set }
    var cancellable: AnyCancellable? { get set }
    
    func willUpdateSelectedPhotoIndex(_ newIndex: Int?)
}

/// This is over-engineered, but is a concept of how we can state manager across the navigationController
extension PhotoContextDelegate {
    /// More efficient than getPhotoDataSource + getSelectedPhotoIndex
    func selectedPhoto() -> UIImage? {
        guard let index = photoGalleryContext.selectedPhotoIndex else {
            logger.error("Tried to access selected photo but no index was set")
            return nil
        }
        
        return photoGalleryContext.photoDataSource.photoAt(index: index)
    }
    
    func photoDataSource() -> PhotoDataSourceProtocol {
        photoGalleryContext.photoDataSource
    }
    
    func swiftUIProvider() -> SwiftUIProviderProtocol {
        photoGalleryContext.swiftUIProvider
    }
    
    func selectedPhotoIndex() -> Int? {
        photoGalleryContext.selectedPhotoIndex
    }
    
    // TODO: Write docs
    func setSelectedPhotoIndex(_ index: Int) {
        guard index >= 0 && index < photoDataSource().numberOfPhotos() else {
            return
        }
        
        photoGalleryContext.selectedPhotoIndex = index
    }
}
