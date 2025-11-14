//
//  PhotoPageView+CollectionDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import UIKit

extension PhotoPageViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)

        //TODO: Finish
    }

    func itemWidth() -> CGFloat {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return -1 }
        return layout.itemSize.width + layout.minimumLineSpacing
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let itemWidth = itemWidth()

        let proposedContentOffset = targetContentOffset.pointee.x + scrollView.contentInset.left
        let index = round(proposedContentOffset / itemWidth)
        let adjustedOffset = index * itemWidth

        targetContentOffset.pointee = CGPoint(x: adjustedOffset, y: 0)

        setSelectedPhotoIndex(Int(index))

        // We don't want to update this collection, so rather we manually set the states necessary internally
        super.willUpdateSelectedPhotoId(typedID(fotoAsset(at: Int(index))))
        resetSwiftUIViews()
    }
}
