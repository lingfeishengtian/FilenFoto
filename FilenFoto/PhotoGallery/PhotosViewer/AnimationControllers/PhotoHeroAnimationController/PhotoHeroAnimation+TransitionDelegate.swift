//
//  PhotoHeroAnimation+TransitionDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import UIKit

extension PhotoHeroAnimationController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        self.heroInteractiveTransition.navigationOperation = .push
        return self.heroInteractiveTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        self.heroInteractiveTransition.navigationOperation = .pop
        return self.heroInteractiveTransition
    }
    
    func interactionControllerForPresentation(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        self.heroInteractiveTransition
    }
    
    func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        self.heroInteractiveTransition
    }
}
