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

class PhotosViewerViewController: PhotoGalleryTemplateViewController {
    var contextHostController: PhotosViewerViewController? = nil

    var collectionView: UICollectionView!
    var itemSize: CGSize!

    var animationController: PhotoHeroAnimationController!

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotosViewerViewController")

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing: CGFloat = 1
        let numberOfItemsPerRow: CGFloat = 5
        let totalSpacing = (numberOfItemsPerRow - 1) * spacing

        let itemWidth = floor((view.frame.width - totalSpacing) / numberOfItemsPerRow)
        itemSize = CGSize(width: itemWidth, height: itemWidth)

        let swiftUIOverlayView = UIHostingController(rootView: AnyView(swiftUIProvider().overlay(for: .galleryView)))
        swiftUIOverlayView.view.backgroundColor = .clear
        swiftUIOverlayView.view.isOpaque = false
        swiftUIOverlayView.view.isUserInteractionEnabled = false
        swiftUIOverlayView.view.frame = self.view.bounds

        // Setup Collection View
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: 80)
        layout.footerReferenceSize = CGSize(width: view.frame.width, height: 50)

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.register(
            CollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionHeader")

        self.view.addSubview(collectionView)
        //        self.view.addSubview(swiftUIOverlayView.view)

        animationController = PhotoHeroAnimationController()
        self.navigationController?.delegate = animationController
    }

    func getSelectedIndexPath() -> IndexPath {
        return IndexPath(item: selectedPhotoIndex() ?? 0, section: 0)
    }

    func willUpdateSelectedPhotoIndex(_ index: Int) {
        focusOnCell(at: getSelectedIndexPath())
    }
}
