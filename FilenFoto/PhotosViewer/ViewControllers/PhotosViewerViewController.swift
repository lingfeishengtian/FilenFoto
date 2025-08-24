//
//  PhotosViewerViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

class PhotosViewerViewController: UIViewController {
    var photos: [UIImage]!

    var collectionView: UICollectionView!
    var itemSize: CGSize!

    // TODO: Rename to transitionController
    let transitionDelegate = PhotoHeroAnimationController()

    fileprivate var selectedIndexPath: IndexPath?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotosViewerViewController")

    override func viewDidLoad() {
        super.viewDidLoad()

        itemSize = CGSize(width: view.frame.width / 3 - 20, height: view.frame.width / 3 - 20)

        // Setup Collection View
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoCell")

        self.view.addSubview(collectionView)
        self.navigationController?.delegate = transitionDelegate
    }

    func getSelectedIndexPath() -> IndexPath {
        guard let indexPath = selectedIndexPath else {
            logger.error("Selected index path is nil, returning default IndexPath(item: 0, section: 0)")
            return IndexPath(item: 0, section: 0)
        }

        return indexPath
    }

    func setSelectedIndexPath(_ indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
}
