//
//  DetailedPhotoView+GestureDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

/// Allow the page controller gesture to activate when horizontal movement is larger than vertical
extension DetailedPhotoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        let velocity = panGesture.velocity(in: view)
        return isVerticalMovement(of: velocity)
    }
}
