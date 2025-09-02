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

        // Setup Collection View
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoCell")

        self.view.addSubview(collectionView)

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
