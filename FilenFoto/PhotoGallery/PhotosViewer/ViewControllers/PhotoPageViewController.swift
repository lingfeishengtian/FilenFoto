//
//  PhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import AVKit
import CoreData
import Foundation
import SwiftUI
import UIKit

class PhotoPageViewController: PagedPhotoDetailViewController {
    var swiftUITopBar: UIHostingController<AnyView>!
    var swiftUIBottomBar: UIHostingController<AnyView>!
    var collectionView: UICollectionView!

    var diffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!

    static let PHOTO_SCRUBBER_HEIGHT: CGFloat = 34
    static let PHOTO_SCRUBBER_WIDTH: CGFloat = 25
    static let PHOTO_SCRUBBER_SPACING: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = PhotoPageViewController.PHOTO_SCRUBBER_SPACING
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: PhotoPageViewController.PHOTO_SCRUBBER_WIDTH, height: PhotoPageViewController.PHOTO_SCRUBBER_HEIGHT)

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(TinyPhotoViewCell.self, forCellWithReuseIdentifier: "TinyPhotoCell")

        swiftUITopBar = UIHostingController(rootView: AnyView(EmptyView()))
        swiftUIBottomBar = UIHostingController(rootView: AnyView(EmptyView()))
        resetSwiftUIViews()

        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.addChild(swiftUITopBar)
        self.addChild(swiftUIBottomBar)
        self.view.addSubview(swiftUITopBar.view)
        self.view.addSubview(swiftUIBottomBar.view)
        self.view.addSubview(collectionView)

        swiftUITopBar.view.translatesAutoresizingMaskIntoConstraints = false
        swiftUIBottomBar.view.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        pagedController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            swiftUITopBar.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            swiftUITopBar.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftUITopBar.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            swiftUITopBar.view.heightAnchor.constraint(equalToConstant: 100),

            pagedController.view.topAnchor.constraint(equalTo: swiftUITopBar.view.bottomAnchor),
            pagedController.view.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
            pagedController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            pagedController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            collectionView.bottomAnchor.constraint(equalTo: swiftUIBottomBar.view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: PhotoPageViewController.PHOTO_SCRUBBER_HEIGHT),

            swiftUIBottomBar.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            swiftUIBottomBar.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftUIBottomBar.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            swiftUIBottomBar.view.heightAnchor.constraint(equalToConstant: 100),
        ])

        DispatchQueue.main.async {
            self.scrollScrubberToSelectedPhoto(animated: false)
        }

        fetchResultsController.delegate = self
        diffableDataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TinyPhotoCell", for: indexPath) as! TinyPhotoViewCell

            let photo = self.thumbnail(at: indexPath)
            cell.configure(with: photo ?? UIImage())

            return cell
        }
        collectionView.dataSource = self.diffableDataSource
        try? fetchResultsController.performFetch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let inset = (collectionView.bounds.width - layout.itemSize.width) / 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }

    func resetSwiftUIViews() {
        guard let currentView = pagedController.viewControllers?.first as? ChildPageTemplateViewController else { return }
        let image = currentView.image.workingAsset

        swiftUITopBar.rootView = AnyView(swiftUIProvider.topBar(with: image))
        swiftUIBottomBar.rootView = AnyView(swiftUIProvider.bottomBar(with: image))
    }

    func scrollScrubberToSelectedPhoto(animated: Bool, to newId: PhotoIdentifier? = nil) {
        guard let selectedId = newId ?? selectedPhotoId, let indexPath = indexPath(for: selectedId) else { return }

        collectionView.setContentOffset(CGPoint(x: Int(itemWidth()) * indexPath.row, y: 0), animated: animated)
    }
    
    override func willUpdateSelectedPhotoId(_ newId: NSManagedObjectID?) {
        super.willUpdateSelectedPhotoId(newId)
        
        if !collectionView.isDragging {
            scrollScrubberToSelectedPhoto(animated: true, to: newId)
        }

        resetSwiftUIViews()
    }

    override func onPageChanged(to id: PhotoIdentifier) {
        scrollScrubberToSelectedPhoto(animated: true, to: id)
    }
}
