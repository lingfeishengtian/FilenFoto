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
    }
}
