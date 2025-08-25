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
            
            return isVerticalMovement(of: velocity)
        }

        return true
    }

    fileprivate func getGestureRecognizer<GestureType>(equivelantTo goalGesture: UIGestureRecognizer, from gestures: [UIGestureRecognizer])
        -> GestureType?
    {
        for gesture in gestures {
            if gesture == goalGesture {
                return gesture as? GestureType
            }
        }

        return nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        let argList = [gestureRecognizer, otherGestureRecognizer]
        let panGestureRecognizer: UIPanGestureRecognizer? = getGestureRecognizer(
            equivelantTo: self.panGestureRecognizer, from: argList)
        let scrollViewPanGestureRecognizer: UIPanGestureRecognizer? = getGestureRecognizer(
            equivelantTo: self.scrollView.panGestureRecognizer, from: argList)
        
        guard let panGestureRecognizer, let scrollViewPanGestureRecognizer else {
            return false
        }
        
        if scrollView.zoomScale != scrollView.minimumZoomScale {
            return false
        }

        return false
    }
}
