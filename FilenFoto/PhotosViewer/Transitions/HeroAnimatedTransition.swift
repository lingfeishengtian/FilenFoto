//
//  HeroAnimatedTransition.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class HeroAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var navigationOperation = UINavigationController.Operation.none
    var transitionImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return navigationOperation == .push ? 0.5 : 0.25
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromView = fromVC.view,
            let toView = toVC.view,
            let fromVCDelegate = fromVC as? PhotoHeroAnimatorDelegate,
            let toVCDelegate = toVC as? PhotoHeroAnimatorDelegate
        else {
            transitionContext.completeTransition(false)

            return
        }

        fromVCDelegate.transitionWillStart()
        toVCDelegate.transitionWillStart()

        let toViewAnimationReferences = toVCDelegate.getAnimationReferences()
        let fromViewAnimationReferences = fromVCDelegate.getAnimationReferences()

        toViewAnimationReferences.imageReference.isHidden = true
        fromViewAnimationReferences.imageReference.isHidden = true

        if navigationOperation == .push {
            containerView.addSubview(toView)
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)
        }

        let image = fromViewAnimationReferences.imageReference.image
        if transitionImageView.superview == nil {
            transitionImageView.frame = fromViewAnimationReferences.frame
            transitionImageView.image = image
            containerView.addSubview(transitionImageView)
        }

        let finalTransitionFrame = toViewAnimationReferences.frame

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [UIView.AnimationOptions.transitionCrossDissolve]
        ) {
            self.transitionImageView.frame = finalTransitionFrame
            toVC.view.alpha = 1
            fromVC.view.alpha = 0
        } completion: { _ in
            self.transitionImageView.removeFromSuperview()
            toViewAnimationReferences.imageReference.isHidden = false
            fromViewAnimationReferences.imageReference.isHidden = false

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromVCDelegate.transitionDidEnd()
            toVCDelegate.transitionDidEnd()
        }
    }
}
