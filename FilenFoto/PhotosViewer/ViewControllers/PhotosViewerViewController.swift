//
//  PhotosViewerViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

class PhotosViewerViewController: UIViewController, PhotoContextDelegate {
    var collectionView: UICollectionView!
    var itemSize: CGSize!

    var animationController: PhotoHeroAnimationController!

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotosViewerViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        itemSize = CGSize(width: view.frame.width / 3 - 1, height: view.frame.width / 3 - 1)

        // Setup Collection View
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1

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
    
    func willUpdateSelectedPhotoIndex(_ index: Int, _ wasSelf: Bool) {
        if !wasSelf {
            focusOnCell(at: getSelectedIndexPath())
        }
    }
}
