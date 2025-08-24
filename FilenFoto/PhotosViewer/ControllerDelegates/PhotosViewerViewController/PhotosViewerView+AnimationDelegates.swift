//
//  PhotosViewerViewController+AnimationDelegates.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation

extension PhotosViewerViewController: PhotoHeroAnimatorDelegate {
    fileprivate func getAnimationReferencesFromCollectionView(for selectedIndexPath: IndexPath) -> AnimationReferences {
        let visibleCells = self.collectionView.indexPathsForVisibleItems
        
        if !visibleCells.contains(selectedIndexPath) {
            self.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.collectionView.layoutIfNeeded()
        }
        
        guard let cell = self.collectionView.cellForItem(at: selectedIndexPath) as? PhotoViewCell else {
            return AnimationReferences(size: itemSize)
        }
        
        return AnimationReferences(imageReference: cell.imageView, frame: self.collectionView.convert(cell.frame, to: self.view))
    }
    
    func getAnimationReferences() -> AnimationReferences {
        getAnimationReferencesFromCollectionView(for: self.getSelectedIndexPath())
    }
    
    func transitionDidEnd() {
        guard let cell = self.collectionView.cellForItem(at: self.getSelectedIndexPath()) as? PhotoViewCell else {
            return
        }
        
        let cellFrameWithinView = self.collectionView.convert(cell.frame, to: self.view)
        
        if cellFrameWithinView.minY < self.collectionView.contentInset.top {
            self.collectionView.scrollToItem(at: self.getSelectedIndexPath(), at: .top, animated: false)
        } else if cellFrameWithinView.maxY > self.view.frame.height - self.collectionView.contentInset.bottom {
            self.collectionView.scrollToItem(at: self.getSelectedIndexPath(), at: .bottom, animated: false)
        }
    }
}
