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
        
        // TODO: This is unacceptable, fix this
        return AnimationReferences(imageReference: cell.imageView, frame: self.collectionView.convert(cell.frame, to: self.view.superview?.superview))
    }
    
    func getAnimationReferences() -> AnimationReferences {
        if let selectedIndexPath {
            return getAnimationReferencesFromCollectionView(for: selectedIndexPath)
        } else {
            return .init(size: .zero)
        }
    }
    
    func transitionDidEnd() {
        if let selectedIndexPath {
            focusOnCell(at: selectedIndexPath)
        }
        
        self.collectionView.isScrollEnabled = true
    }
    
    func transitionWillStart() {
        self.collectionView.isScrollEnabled = false
    }
}
