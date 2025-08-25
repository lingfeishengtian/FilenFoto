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
        self.detailedInfoTransition.navigationOperation = operation
        self.detailedInfoInteractiveTransition.navigationOperation = operation
        
        if fromVC is PagedPhotoDetailViewController && toVC is PagedPhotoDetailViewController {
            return self.detailedInfoTransition
        }

        return self.heroAnimationTransition
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController:
            any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        if isInteractive {
            if animationController is DetailedInfoTransition {
                return self.detailedInfoInteractiveTransition
            }
            
            return self.heroInteractiveTransition
        }

        return nil
    }
}
