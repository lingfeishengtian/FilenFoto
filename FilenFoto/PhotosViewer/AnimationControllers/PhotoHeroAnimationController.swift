//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroAnimationTransition = HeroAnimatedTransition()
    let interactiveTransition = InteractiveHeroAnimatedTransition()
    var isInteractive = false

    func handleInteractiveTransitionPan(_ gestureRecognizer: UIPanGestureRecognizer, _ navigationController: UINavigationController?) {
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)

        switch gestureRecognizer.state {
        case .began:
            if direction(of: velocity) == .down {
                isInteractive = true
                navigationController?.popViewController(animated: true)
            }
        case .changed:
            if isInteractive {
                interactiveTransition.handlePan(gestureRecognizer)
            }
        case .ended:
            if isInteractive {
                interactiveTransition.handlePan(gestureRecognizer)
                isInteractive = false
            }
        default:
            // TODO: Remove this debug print
            print("Unhandled gesture state: \(gestureRecognizer.state)")
        }
    }
}
