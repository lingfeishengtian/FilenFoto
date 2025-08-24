//
//  PhotosViewerViewController+CollectionViewDataSource.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

extension PhotosViewerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        let photo = self.photos[indexPath.item]
        cell.configure(with: photo)
        
        return cell
    }
}
