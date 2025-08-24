//
//  PhotoHeroAnimationController+NavigationDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

extension PhotoHeroAnimationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        self.heroAnimationTransition.navigationOperation = operation

        return self.heroAnimationTransition
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController:
            any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        if isInteractive {
            return self.interactiveTransition
        }

        return nil
    }
}
