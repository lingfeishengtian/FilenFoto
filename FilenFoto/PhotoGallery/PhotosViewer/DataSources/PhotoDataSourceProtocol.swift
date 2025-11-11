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
    /// - Parameter photoId: The `FotoAsset` for which the thumbnail is requested for
    /// - Returns a UIImage containing the thumbnail image
    func thumbnail(for photoId: FotoAsset) -> UIImage?
    
    /// A synchronous call that retrieves an `FFDisplayableImage` for the current `FotoAsset`
    ///
    /// `FFDisplayableImage` implementations should show a thumbnail that can be instaneously
    /// obtained and load the full size image in the background to then show to the user after preparing
    /// for display.
    ///
    /// - Parameter photoId: The `FotoAsset` for which the `FFDisplayableImage` is requested for
    /// - Returns a `FFDisplayableImage`
    func photo(for photoId: FotoAsset) -> FFDisplayableImage?
    func fetchRequestController() -> NSFetchedResultsController<FotoAsset>
}
