//
//  PhotoDataSourceProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import CoreData

protocol PhotoDataSourceProtocol {
    func photo(for photoId: FotoAsset) -> UIImage?
    func fetchRequestController() -> NSFetchedResultsController<FotoAsset>
}
