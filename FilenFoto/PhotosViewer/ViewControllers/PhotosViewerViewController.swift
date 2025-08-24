//
//  PhotosViewerViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

class PhotosViewerViewController: UIViewController, PhotoContextHost {
    var selectedPhotoIndex: Int?
    var photoDataSource: PhotoDataSourceProtocol?

    var collectionView: UICollectionView!
    var itemSize: CGSize!

    // TODO: Rename to transitionController
    let transitionDelegate = PhotoHeroAnimationController()

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
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoCell")

        self.view.addSubview(collectionView)
        self.navigationController?.delegate = transitionDelegate
    }
    
    func getSelectedIndexPath() -> IndexPath {
        return IndexPath(item: selectedPhotoIndex ?? 0, section: 0)
    }
    
    func willUpdateSelectedPhotoIndex(_ index: Int) {
        focusOnCell(at: getSelectedIndexPath())
    }
}
