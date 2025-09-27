//
//  PhotosViewerView+NSFetchResultsControllerDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/26/25.
//

import Foundation
import CoreData
import UIKit

extension PhotosViewerViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.diffableDataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>)
    }
}
