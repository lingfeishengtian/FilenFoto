//
//  PhotoPageViewController+CollectionViewDataSource.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import UIKit

extension PhotoPageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoDataSource().numberOfPhotos()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TinyPhotoCell", for: indexPath) as! TinyPhotoViewCell
        
        let photo = photoDataSource().photoAt(index: indexPath.item) ?? UIImage()
        cell.configure(with: photo)

        return cell
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
        super.willUpdateSelectedPhotoIndex(Int(index))
        resetSwiftUIViews()
    }
}
