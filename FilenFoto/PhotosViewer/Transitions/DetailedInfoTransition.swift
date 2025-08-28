//
//  DetailedInfoTransition.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

class DetailedInfoTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var navigationOperation = UINavigationController.Operation.none
    var transitionImageView: UIImageView!

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return navigationOperation == .push ? 0.5 : 0.25
    }

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

        toVC.view.alpha = 0

        let toViewAnimationReferences = toVCDelegate.getAnimationReferences()
        let fromViewAnimationReferences = fromVCDelegate.getAnimationReferences()

//        toViewAnimationReferences.imageReference.isHidden = true
        fromViewAnimationReferences.imageReference.isHidden = true

        if navigationOperation == .push {
            containerView.addSubview(toView)
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)
        }

        let image = fromViewAnimationReferences.imageReference.image
        if transitionImageView == nil {
            transitionImageView = toViewAnimationReferences.imageReference
            transitionImageView.frame = fromViewAnimationReferences.frame

//            containerView.addSubview(transitionImageView)
        }
        
        toVC.viewDidLoad()
        print(toView.gestureRecognizers)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [UIView.AnimationOptions.transitionCrossDissolve]
        ) {
            toView.layoutIfNeeded()

            let finalFrame = toVCDelegate.getAnimationReferences().frame

            self.transitionImageView.frame = finalFrame
            self.transitionImageView.transform = .identity
            toVC.view.alpha = 1
        } completion: { _ in
//            self.transitionImageView.removeFromSuperview()
//            toViewAnimationReferences.imageReference.isHidden = false
            fromViewAnimationReferences.imageReference.isHidden = false

//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromVCDelegate.transitionDidEnd()
            toVCDelegate.transitionDidEnd()
        }
    }
}
