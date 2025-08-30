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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoViewCell
        
        let photo = photoDataSource().photoAt(index: indexPath.item) ?? UIImage()
        cell.configure(with: photo)
        
        return cell
    }
}
