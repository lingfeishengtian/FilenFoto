//
//  DetailedInfoInteractiveTransition.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

fileprivate let SLOW_MULTIPLIER: CGFloat = 2.0
fileprivate let THRESHOLD: CGFloat = 0.3

class DetailedInfoInteractiveTransition: NSObject, UIViewControllerInteractiveTransitioning {
    var navigationOperation = UINavigationController.Operation.none
    var transitionContext: (any UIViewControllerContextTransitioning)?
    var transitionImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    func shouldCenterImage(viewController: UIViewController) -> Bool {
        guard let vc = viewController as? PagedPhotoDetailViewController else {
            return false
        }
        
        return vc.PageType == PhotoPageViewController.self
    }
    
    fileprivate func centerAndResizeIfNeeded(viewController: UIViewController, in frame: CGRect) {
        if shouldCenterImage(viewController: viewController) {
            centerAndResize(imageView: self.transitionImageView, in: frame)
        }
    }
    
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
        let verticalDelta: CGFloat = {
            if self.navigationOperation == .push {
                return translation.y > 0 ? 0 : translation.y
            } else {
                return translation.y < 0 ? 0 : translation.y
            }
        }()

        let progress = min(abs(verticalDelta / fromViewAnimationReferences.imageReference.frame.height), 1)

        let currentHeight = fromViewAnimationReferences.imageReference.frame.height
        let destinationHeight = toViewAnimationReferences.imageReference.frame.height
            
        let heightDelta = currentHeight - destinationHeight
        let height = (currentHeight - (heightDelta * progress))
        
        transitionImageView.frame.size.height = height
        transitionImageView.center = CGPoint(x: anchorPoint.x, y: anchorPoint.y + verticalDelta)

        transitionContext.updateInteractiveTransition(progress)
        
        if gestureRecognizer.state == .ended {
            func defaultCompletion() {
                toViewAnimationReferences.imageReference.isHidden = false
                fromViewAnimationReferences.imageReference.isHidden = false

                transitionImageView.removeFromSuperview()
                self.transitionContext = nil

                fromVCDelegate.transitionDidEnd()
                toVCDelegate.transitionDidEnd()
            }

            if progress < THRESHOLD || (self.navigationOperation == .push && gestureRecognizer.velocity(in: fromVC.view).y > 0) || (self.navigationOperation == .pop && gestureRecognizer.velocity(in: fromVC.view).y < 0) {
                // The user wants to cancel the transition
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 0,
                    options: [],
                    animations: {
                        self.transitionImageView.frame = fromViewAnimationReferences.frame
                        self.centerAndResizeIfNeeded(viewController: fromVC, in: fromViewAnimationReferences.frame)
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
                options: [.transitionCrossDissolve],
                animations: {
                    self.transitionImageView.frame = toViewAnimationReferences.frame
                    self.centerAndResizeIfNeeded(viewController: toVC, in: toViewAnimationReferences.frame)
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

            centerAndResize(imageView: transitionImageView, in: animationReferences.frame)

            containerView.addSubview(transitionImageView)
        }
    }
}
