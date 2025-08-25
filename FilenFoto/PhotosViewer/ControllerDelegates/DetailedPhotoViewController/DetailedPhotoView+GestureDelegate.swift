//
//  DetailedPhotoView+GestureDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

extension DetailedPhotoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        let velocity = panGesture.velocity(in: view)
        return direction(of: velocity) == .down
    }
}
