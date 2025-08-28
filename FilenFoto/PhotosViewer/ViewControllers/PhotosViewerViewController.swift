//
//  PhotosViewerViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

class PhotosViewerViewController: UIViewController, PhotoContextHost, UIGestureRecognizerDelegate {
    var selectedPhotoIndex: Int?
    var photoDataSource: PhotoDataSourceProtocol?
    var detailedPhotoViewBuilder: DetailedPhotoViewBuilder?

    var collectionView: UICollectionView!
    var itemSize: CGSize!

    // TODO: Rename to transitionController
    var transitionDelegate: PhotoHeroAnimationController!

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotosViewerViewController")
    
    lazy var panGestureRecognizer = UIPanGestureRecognizer()

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
        
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
        panGestureRecognizer.delegate = self
        transitionDelegate = PhotoHeroAnimationController(navigatorControllerPanGesture: panGestureRecognizer)
        
        self.navigationController?.delegate = transitionDelegate
        
        guard let interactivePopGestureRecognizer = self.navigationController?.interactivePopGestureRecognizer else { return }
        panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
        
        self.navigationController?.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    func getSelectedIndexPath() -> IndexPath {
        return IndexPath(item: selectedPhotoIndex ?? 0, section: 0)
    }
    
    func willUpdateSelectedPhotoIndex(_ index: Int) {
        focusOnCell(at: getSelectedIndexPath())
    }
    
    // MARK: - Gesture Recognizers
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let velocity = gestureRecognizer.velocity(in: self.view)
//        print("Pan velocity: \(velocity)")
//        transitionDelegate.isInteractive = true
//        transitionDelegate.heroInteractiveTransition.handlePan(gestureRecognizer)
//        
//        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
//            transitionDelegate.isInteractive = false
//        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
