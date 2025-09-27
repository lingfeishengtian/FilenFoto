//
//  PhotosViewerViewController+AnimationDelegates.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation

extension PhotosViewerViewController: PhotoHeroAnimatorDelegate {
    fileprivate func getAnimationReferencesFromCollectionView(for selectedIndexPath: IndexPath) -> AnimationReferences {
        focusOnCell(at: selectedIndexPath)
        
        guard let cell = self.collectionView.cellForItem(at: selectedIndexPath) as? PhotoViewCell else {
            return AnimationReferences(size: itemSize)
        }
        
        return AnimationReferences(imageReference: cell.imageView, frame: self.collectionView.convert(cell.frame, to: self.view.superview?.superview))
    }
    
    func getAnimationReferences() -> AnimationReferences {
        getAnimationReferencesFromCollectionView(for: getSelectedIndexPath())
    }
    
    func transitionDidEnd() {
        focusOnCell(at: getSelectedIndexPath())
        
        self.collectionView.isScrollEnabled = true
    }
    
    func transitionWillStart() {
        self.collectionView.isScrollEnabled = false
    }
}
