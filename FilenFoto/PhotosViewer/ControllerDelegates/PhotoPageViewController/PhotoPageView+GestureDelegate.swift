//
//  GestureDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

extension PhotoPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
            
            return isVerticalMovement(of: velocity) && scrollView.zoomScale == scrollView.minimumZoomScale
        }

        return true
    }
}
