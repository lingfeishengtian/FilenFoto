//
//  PhotosViewerViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import SwiftUI
import UIKit
import os
import CoreData

class PhotosViewerViewController: PhotoGalleryTemplateViewController {
    var collectionView: UICollectionView!
    var noImagesHostingController: UIHostingController<AnyView>!
    var itemSize: CGSize!

    var animationController: PhotoHeroAnimationController!
    var diffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotosViewerViewController")

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing: CGFloat = 1
        let numberOfItemsPerRow: CGFloat = 5
        let totalSpacing = (numberOfItemsPerRow - 1) * spacing

        let itemWidth = floor((view.frame.width - totalSpacing) / numberOfItemsPerRow)
        itemSize = CGSize(width: itemWidth, height: itemWidth)

        // Setup Collection View
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.contentInset.top = 70
        
        noImagesHostingController = UIHostingController(rootView: AnyView(swiftUIProvider.noImagesAvailableView()))
        noImagesHostingController.view.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(collectionView)
        self.view.addSubview(noImagesHostingController.view)
        
        NSLayoutConstraint.activate([
            noImagesHostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            noImagesHostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            noImagesHostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            noImagesHostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        animationController = PhotoHeroAnimationController()
        self.navigationController?.delegate = animationController
        
        self.diffableDataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID> (collectionView: self.collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
            
            let photo = self.thumbnail(at: indexPath)
            cell.configure(with: photo ?? UIImage())
            
            return cell
        }
        collectionView.dataSource = diffableDataSource
        fetchResultsController.delegate = self
        try? fetchResultsController.performFetch()
    }
    
    override func willUpdateSelectedPhotoId(_ newId: PhotoIdentifier?) {
        guard let newId, let indexPath = indexPath(for: newId) else {
            return
        }
        
        focusOnCell(at: indexPath)
    }
}
