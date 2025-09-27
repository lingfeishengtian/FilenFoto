//
//  PhotoGalleryTemplateViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import UIKit
import Combine
import os
import CoreData

class PhotoGalleryTemplateViewController: UIViewController {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FilenFoto", category: "PhotoGalleryTemplateViewController")

    var photoGalleryContext: PhotoGalleryContext
    var fetchResultsController: NSFetchedResultsController<FotoAsset>
    
    var cancellable: AnyCancellable?
    
    /// Called just before the selected photo index is updated from the context.
    /// *Note:* The new Index will be different from the current selected index since this function is called before the update occurs.
    func willUpdateSelectedPhotoIndex(_ newIndex: Int?) { }
    
    init (photoGalleryContext: PhotoGalleryContext) {
        self.photoGalleryContext = photoGalleryContext
        self.fetchResultsController = photoGalleryContext.photoDataSource.fetchRequestController()
        
        super.init(nibName: nil, bundle: nil)
        
        self.cancellable = self.photoGalleryContext.$selectedPhotoIndex
            .removeDuplicates()
            .sink { [weak self] newIndex in
                guard let self, self.isViewLoaded, localSelectedPhotoIndex != newIndex else { return }

                self.willUpdateSelectedPhotoIndex(newIndex)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var countOfPhotos: Int {
        fetchResultsController.sections?.first?.numberOfObjects ?? 0
    }
    
    func photo(at index: Int) -> UIImage? {
        photo(at: IndexPath(row: index, section: 0))
    }
    
    func photo(at indexPath: IndexPath) -> UIImage? {
        photoDataSource().photo(for: fetchResultsController.object(at: indexPath))
    }
    
    func selectedPhoto() -> UIImage? {
        guard let index = photoGalleryContext.selectedPhotoIndex else {
            logger.error("Tried to access selected photo but no index was set")
            return nil
        }
        
        return photo(at: index)
    }
    
    func photoDataSource() -> PhotoDataSourceProtocol {
        photoGalleryContext.photoDataSource
    }
    
    func swiftUIProvider() -> SwiftUIProviderProtocol {
        photoGalleryContext.swiftUIProvider
    }
    
    private var localSelectedPhotoIndex: Int? = nil
    
    func selectedPhotoIndex() -> Int? {
        localSelectedPhotoIndex ?? photoGalleryContext.selectedPhotoIndex
    }
    
    /// Sets the local selected photo index without committing it to the context.
    /// This allows for temporary changes that can be committed later to prevent animation jumps within the current view
    /// Every change *must* be committed before the view is dismissed or a new view is presented to prevent inconsistencies
    func setSelectedPhotoIndex(_ index: Int) {
        guard index >= 0 && index < countOfPhotos else {
            return
        }
        
        localSelectedPhotoIndex = index
    }
    
    /// Commits any local selected photo index changes to the context and calls `willUpdateSelectedPhotoIndex` on all subscribers
    func commitLocalSelectedPhotoIndex() {
        if let localIndex = localSelectedPhotoIndex {
            photoGalleryContext.selectedPhotoIndex = localIndex
            localSelectedPhotoIndex = nil
        }
    }
}
