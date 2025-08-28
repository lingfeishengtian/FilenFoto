//
//  PhotoHeroAnimationController+GestureDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/27/25.
//

import Foundation
import UIKit

// MARK: - Navigation Controller Pan Gesture Delegate

extension PhotoHeroAnimationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
