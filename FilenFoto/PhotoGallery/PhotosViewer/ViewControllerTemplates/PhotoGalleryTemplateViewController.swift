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
    private var localSelectedPhotoId: PhotoIdentifier? = nil
    
    /// Called just before the selected photo index is updated from the context.
    /// *Note:* The new Index will be different from the current selected index since this function is called before the update occurs.
    func willUpdateSelectedPhotoId(_ newId: PhotoIdentifier?) { }
    
    init (photoGalleryContext: PhotoGalleryContext) {
        self.photoGalleryContext = photoGalleryContext
        self.fetchResultsController = photoGalleryContext.photoDataSource.fetchRequestController()
        
        super.init(nibName: nil, bundle: nil)
        
        self.cancellable = self.photoGalleryContext.$selectedPhotoId
            .removeDuplicates()
            .sink { [weak self] newId in
                guard let self, self.isViewLoaded, localSelectedPhotoId != newId else { return }

                self.willUpdateSelectedPhotoId(newId)
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
    
    func photo(for objectId: PhotoIdentifier) -> UIImage? {
        guard let fotoAsset = fotoAsset(for: objectId) else {
            return nil
        }
        
        return photoDataSource().photo(for: fotoAsset)
    }
    
    func fotoAsset(for objectId: PhotoIdentifier) -> FotoAsset? {
        fetchResultsController.managedObjectContext.object(with: objectId) as? FotoAsset
    }
    
    func indexPath(for objectId: PhotoIdentifier) -> IndexPath? {
        guard let object = fetchResultsController.managedObjectContext.object(with: objectId) as? FotoAsset else {
            return nil
        }
        
        return fetchResultsController.indexPath(forObject: object)
    }
    
    func selectedPhoto() -> UIImage? {
        guard let selectedPhotoId = photoGalleryContext.selectedPhotoId else {
            logger.error("Tried to access selected photo but no photo was set")
            return nil
        }
        
        return photo(for: selectedPhotoId)
    }
    
    var selectedIndexPath: IndexPath? {
        guard let selectedPhotoId = photoGalleryContext.selectedPhotoId else {
            return nil
        }
        
        return self.indexPath(for: selectedPhotoId)
    }
    
    func photoDataSource() -> PhotoDataSourceProtocol {
        photoGalleryContext.photoDataSource
    }
    
    func swiftUIProvider() -> SwiftUIProviderProtocol {
        photoGalleryContext.swiftUIProvider
    }
    
    func selectedPhotoId() -> PhotoIdentifier? {
        photoGalleryContext.selectedPhotoId
    }
    
    /// Sets the local selected photo without committing it to the context.
    /// This allows for temporary changes that can be committed later to prevent animation jumps within the current view
    /// Every change **must** be committed before the view is dismissed or a new view is presented to prevent inconsistencies
    func setSelectedPhotoIndex(_ index: Int) {
        guard index >= 0 && index < countOfPhotos else {
            return
        }
        
        localSelectedPhotoId = fetchResultsController.object(at: IndexPath(row: index, section: 0)).objectID
    }
    
    func setSelectedPhotoId(_ id: PhotoIdentifier) {
        localSelectedPhotoId = id
    }
    
    /// Commits any local selected photo index changes to the context and calls `willUpdateSelectedPhotoId` on all subscribers
    func commitLocalSelectedPhotoIndex() {
        if let localPhotoId = localSelectedPhotoId {
            photoGalleryContext.selectedPhotoId = localPhotoId
            localSelectedPhotoId = nil
        }
    }
}
