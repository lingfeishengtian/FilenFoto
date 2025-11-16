//
//  PhotosViewerViewController+CollectionView.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

extension PhotosViewerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setSelectedPhotoIndex(indexPath.item)
        
        let detailVC = PhotoPageViewController(animationController: animationController, photoGalleryContext: self.photoGalleryContext)
        
        let navigationControllerWrapper = UINavigationController(rootViewController: detailVC)
        
        navigationControllerWrapper.modalPresentationStyle = .custom
        navigationControllerWrapper.isModalInPresentation = true
        navigationControllerWrapper.delegate = self.animationController
        navigationControllerWrapper.transitioningDelegate = self.animationController
        
        navigationControllerWrapper.navigationBar.isHidden = true
        
        commitLocalSelectedPhotoIndex()
        
        self.animationController.beginHeroInteractiveTransition(initiallyInteractive: false, from: self, to: detailVC)
        self.present(navigationControllerWrapper, animated: true)
    }

    func focusOnCell(at indexPath: IndexPath) {
        let visibleCells = self.collectionView.indexPathsForVisibleItems

        if !visibleCells.contains(indexPath) {
            let scrollPosition: UICollectionView.ScrollPosition = (visibleCells.first?.item ?? -1) > indexPath.item ? .top : .bottom
            
            self.collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: false)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.collectionView.layoutIfNeeded()
        } else {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PhotoViewCell else {
                return
            }
            
            let cellFrameWithinView = self.collectionView.convert(cell.frame, to: self.view)
            
            if cellFrameWithinView.minY < self.collectionView.contentInset.top {
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            } else if cellFrameWithinView.maxY > self.view.frame.height - self.collectionView.contentInset.bottom {
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
}
