//
//  InteractiveHeroAnimatedTransition.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class InteractiveHeroAnimatedTransition: NSObject, UIViewControllerInteractiveTransitioning {
    var transitionContext: (any UIViewControllerContextTransitioning)?
    var transitionImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext = transitionContext,
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVCDelegate = toVC as? PhotoHeroAnimatorDelegate,
            let fromVCDelegate = fromVC as? PhotoHeroAnimatorDelegate
        else {
            transitionContext?.cancelInteractiveTransition()
            transitionContext?.completeTransition(false)

            return
        }

        fromVCDelegate.transitionWillStart()
        toVCDelegate.transitionWillStart()

        let toViewAnimationReferences = toVCDelegate.getAnimationReferences()
        let fromViewAnimationReferences = fromVCDelegate.getAnimationReferences()

        toViewAnimationReferences.imageReference.isHidden = true
        fromViewAnimationReferences.imageReference.isHidden = true

        let anchorPoint = anchorPoint(of: fromViewAnimationReferences.imageReference, in: fromVC.view)
        let translation = gestureRecognizer.translation(in: fromVC.view)
        let verticalDelta: CGFloat = translation.y < 0 ? 0 : translation.y  // Negative means this gesture is out of bounds

        let alpha = alpha(for: fromVC.view, with: verticalDelta)
        let scale = scale(for: fromVC.view, with: verticalDelta)

        fromVC.view.alpha = alpha
        // TODO: Deal with navbar??

        let scaledHeightOffset = transitionImageView.bounds.height * (1 - scale) / 2

        transitionImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        transitionImageView.center = CGPoint(x: anchorPoint.x + translation.x, y: anchorPoint.y + translation.y - scaledHeightOffset)

        transitionContext.updateInteractiveTransition(1 - scale)  // TODO: This feels wrong

        if gestureRecognizer.state == .ended {
            func defaultCompletion() {
                toViewAnimationReferences.imageReference.isHidden = false
                fromViewAnimationReferences.imageReference.isHidden = false

                transitionImageView.removeFromSuperview()
                self.transitionContext = nil

                fromVCDelegate.transitionDidEnd()
                toVCDelegate.transitionDidEnd()
            }

            if direction(of: gestureRecognizer.velocity(in: fromVC.view)) == .up || transitionImageView.center.y < anchorPoint.y {
                // The user wants to cancel the transition
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 0,
                    options: [],
                    animations: {
                        self.transitionImageView.frame = fromViewAnimationReferences.frame
                        fromVC.view.alpha = 1.0
                    },
                    completion: { completion in
                        transitionContext.cancelInteractiveTransition()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                        defaultCompletion()
                    })

                return
            }

            // The user wants to finish the transition
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [],
                animations: {
                    self.transitionImageView.frame = toViewAnimationReferences.frame
                    fromVC.view.alpha = 0
                },
                completion: { completion in
                    transitionContext.finishInteractiveTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                    defaultCompletion()
                })
        }
    }

    func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromVCDelegate = fromVC as? PhotoHeroAnimatorDelegate
        else {
            transitionContext.completeTransition(false)

            return
        }

        self.transitionContext = transitionContext

        let containerView = transitionContext.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        let animationReferences = fromVCDelegate.getAnimationReferences()

        toVC.view.alpha = 1.0

        if transitionImageView.superview == nil {
            transitionImageView.frame = animationReferences.frame
            transitionImageView.image = animationReferences.imageReference.image

            containerView.addSubview(transitionImageView)
        }
    }
}
