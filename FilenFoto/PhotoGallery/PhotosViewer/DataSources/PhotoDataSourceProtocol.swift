//
//  PhotoDataSourceProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import CoreData

/// The PhotoGallery depends on this data source protocol to retrieve images to display on the screen.
/// Internally, the PhotoGallery does not cache the data it receives and may call the same photo multiple times.
/// You may also not assume that the same photo will be requested synchronously, meaning the same photo
/// may be called multiple times concurrently.
protocol PhotoDataSourceProtocol {
    /// Request for a shrunken more compact version of the original image
    ///
    /// - Parameter photoId: The FotoAsset for which the thumbnail is requested for
    /// - Returns a UIImage containing the thumbnail image
    func thumbnail(for photoId: FotoAsset) -> UIImage?
    
    /// An asynchronous request for the original photo asset
    func photo(for photoId: FotoAsset) -> FFDisplayableImage?
    func fetchRequestController() -> NSFetchedResultsController<FotoAsset>
}
