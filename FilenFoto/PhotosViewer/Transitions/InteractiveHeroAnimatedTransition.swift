//
//  InteractiveHeroAnimatedTransition.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os


class InteractiveHeroAnimatedTransition: NSObject, UIViewControllerInteractiveTransitioning, UIViewControllerAnimatedTransitioning {
    let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "InteractiveHeroAnimatedTransition")

    var transitionContext: (any UIViewControllerContextTransitioning)?

    var isInteractive = false
    var initiallyInteractive = false {
        didSet {
            isInteractive = initiallyInteractive
        }
    }

    var wantsInteractiveStart: Bool {
        return initiallyInteractive
    }

    var navigationOperation = UINavigationController.Operation.none
    var transitionImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.clipsToBounds = true

        return imageView
    }()

    lazy var viewTransitionAnimator: UIViewPropertyAnimator = {
        return UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)
    }()
    var imageAnimator: UIViewPropertyAnimator = {
        return UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)
    }()

    func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        setupAnimator(using: transitionContext)
    }

    var previousAnchorPoint = CGPoint.zero
    
    override init() {
        super.init()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        transitionImageView.isUserInteractionEnabled = true
        transitionImageView.addGestureRecognizer(panGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        longPressGesture.minimumPressDuration = 0.0
        transitionImageView.addGestureRecognizer(longPressGesture)
        
        panGesture.delegate = self
        longPressGesture.delegate = self
    }

    @objc func handlePan(_ gestureRecognizer: UIGestureRecognizer) {
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

        let containerView = transitionContext.containerView
        
        let toViewAnimationReferences = toVCDelegate.getAnimationReferences()
        let fromViewAnimationReferences = fromVCDelegate.getAnimationReferences()

        if gestureRecognizer.state == .began, let longPressGesture = gestureRecognizer as? UILongPressGestureRecognizer, let presentation = transitionImageView.layer.presentation() {
            pauseAnimationsToPrepareForInteraction()
            
//            previousAnchorPoint = anchorPoint(of: transitionImageView, in: containerView)
//            previousAnchorPoint = longPressGesture.location(in: containerView)
            previousAnchorPoint = presentation.position
            print("Gesture began at: \(transitionImageView.frame)")
            

            fromVCDelegate.transitionWillStart()
            toVCDelegate.transitionWillStart()
        }

        let anchorPoint = previousAnchorPoint
        toViewAnimationReferences.imageReference.isHidden = true
        fromViewAnimationReferences.imageReference.isHidden = true

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: containerView)
//            let verticalDelta = abs(translation.y)  // Negative means this gesture is out of bounds
            
//            let progress = verticalDelta / containerView.bounds.height / 2
//            transitionContext.updateInteractiveTransition(progress)
            
//            let scaleWidth = lerp(from: fromViewAnimationReferences.frame.width, to: toViewAnimationReferences.frame.width, with: progress)
            //        let alpha = alpha(for: fromVC.view, with: verticalDelta)
            //        let scale = scale(for: fromVC.view, with: verticalDelta)
            
            //        fromVC.view.alpha = alpha
            // TODO: Deal with navbar??
            
//            transitionImageView.transform = CGAffineTransform(scaleX: scaleWidth / self.transitionImageView.frame.width, y: 1)
            transitionImageView.center = CGPoint(x: anchorPoint.x + translation.x, y: anchorPoint.y + translation.y)
        }

        //        animator.fractionComplete = 1 - scale
        //        transitionContext.updateInteractiveTransition(1 - scale)  // TODO: This feels wrong

        if gestureRecognizer.state == .ended, let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: fromVC.view)

            transitionContext.finishInteractiveTransition()

            resetImageAnimator()
            
            if direction(of: velocity) == .down {
                viewTransitionAnimator.isReversed = true
                imageAnimator.addAnimations {
                    self.transitionImageView.frame = fromViewAnimationReferences.frame
                    self.centerAndResizeIfNeeded(viewController: fromVC, in: fromViewAnimationReferences.frame)
                }
            } else {
                viewTransitionAnimator.isReversed = false
                imageAnimator.addAnimations {
                    self.transitionImageView.frame = toViewAnimationReferences.frame
                    self.centerAndResizeIfNeeded(viewController: toVC, in: toViewAnimationReferences.frame)
                }
            }
            
            let durationFactor = CGFloat(imageAnimator.duration / viewTransitionAnimator.duration)

            continueAnimationsAfterInteractionEnds(durationFactor: 0.8)
        }
    }

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
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func setupAnimator(using transitionContext: any UIViewControllerContextTransitioning) {
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

        self.transitionContext = transitionContext
        
        viewTransitionAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)

        fromVCDelegate.transitionWillStart()
        toVCDelegate.transitionWillStart()

        toVC.view.alpha = 0

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

            centerAndResizeIfNeeded(viewController: fromVC, in: fromViewAnimationReferences.frame)
            containerView.addSubview(transitionImageView)
        }

        let finalTransitionFrame = toViewAnimationReferences.frame
        
        resetImageAnimator()
        
        imageAnimator.addAnimations {
            self.transitionImageView.frame = self.shouldCenterImage(viewController: toVC) ? getCenteredAndResizedFrame(for: self.transitionImageView, in: finalTransitionFrame) : finalTransitionFrame
//            self.centerAndResizeIfNeeded(viewController: toVC, in: finalTransitionFrame)
        }

        viewTransitionAnimator.addAnimations {
            toVC.view.alpha = 1
        }

        viewTransitionAnimator.addCompletion { position in
            self.transitionImageView.removeFromSuperview()
            toViewAnimationReferences.imageReference.isHidden = false
            fromViewAnimationReferences.imageReference.isHidden = false

            transitionContext.completeTransition(position == .end)

            fromVCDelegate.transitionDidEnd()
            toVCDelegate.transitionDidEnd()
        }

        startAnimationsOnInitiallyInteractive()
    }

    func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning) -> any UIViewImplicitlyAnimating {
        return viewTransitionAnimator
    }
}

extension InteractiveHeroAnimatedTransition {

    func pauseAnimationsToPrepareForInteraction() {
        guard !isInteractive else { return }

        viewTransitionAnimator.pauseAnimation()
        print("imageFrame", transitionImageView.frame)
        
        if let presenting = transitionImageView.layer.presentation() {
            print("presentation frame", presenting.frame)
        }
        
        imageAnimator.stopAnimation(true)
        print("imageFrame", transitionImageView.frame)

        isInteractive = true
    }

    func continueAnimationsAfterInteractionEnds(durationFactor: CGFloat) {
        guard isInteractive else { return }
        
        if viewTransitionAnimator.state == .inactive {
            viewTransitionAnimator.startAnimation()
        } else {
            viewTransitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
        
        if imageAnimator.state == .inactive {
            imageAnimator.startAnimation()
        } else {
            imageAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }

        isInteractive = false
    }

    func startAnimationsOnInitiallyInteractive() {
        guard !initiallyInteractive else {
            viewTransitionAnimator.pauseAnimation()
            imageAnimator.pauseAnimation()

            return
        }

        viewTransitionAnimator.startAnimation()
        imageAnimator.startAnimation()
    }
    
    func resetImageAnimator() {
        if imageAnimator.state != .inactive {
            logger.error("Image animator not inactive while resetting Image Animator. This is an issue")
            // stack trace
            let symbols = Thread.callStackSymbols
            for symbol in symbols {
                logger.error("\(symbol)")
            }
        }
//        imageAnimator.finishAnimation(at: .current)

        imageAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)
    }
}

extension InteractiveHeroAnimatedTransition: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
        
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
