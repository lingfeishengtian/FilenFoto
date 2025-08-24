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
        let selectedPhoto = self.photos[indexPath.item]
        
        let detailVC = PhotoDetailViewController()
        detailVC.animationController = self.transitionDelegate
        detailVC.configure(with: selectedPhoto)
        
        self.setSelectedIndexPath(indexPath)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
