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
    // MARK: Private variables
    private let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "InteractiveHeroAnimatedTransition")
    private var transitionImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.clipsToBounds = true

        return imageView
    }()
    private var transitionContext: (any UIViewControllerContextTransitioning)?

    // MARK: Interactivity variables
    internal var isInteractive = false
    var wantsInteractiveStart: Bool = false {
        didSet {
            isInteractive = wantsInteractiveStart
        }
    }

    var navigationOperation = UINavigationController.Operation.none

    var viewTransitionAnimator = getNewViewPropertyAnimator()
    var imageAnimator = getNewViewPropertyAnimator()

    func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        setupAnimator(using: transitionContext)
    }

    var previousAnchorFrame: CGRect? = nil
    var originPoint: CGPoint? = nil

    let movableXAxis: Bool

    /// Should never be called
    private override init() { fatalError() }

    init(movableXAxis: Bool) {
        self.movableXAxis = movableXAxis
        super.init()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        transitionImageView.isUserInteractionEnabled = true
        transitionImageView.addGestureRecognizer(panGesture)

        panGesture.delegate = self
    }

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext = transitionContext,
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from)
        else {
            transitionContext?.cancelInteractiveTransition()
            transitionContext?.completeTransition(false)

            return
        }

        let containerView = transitionContext.containerView

        guard transitionImageView.superview != nil else {
            return
        }

        if previousAnchorFrame == nil {
            pauseAnimationsToPrepareForInteraction()
            previousAnchorFrame = transitionImageView.frame
            originPoint = gestureRecognizer.location(in: containerView)
        }

        let anchorPoint = CGPoint(x: previousAnchorFrame!.midX, y: previousAnchorFrame!.midY)

        // TODO: make better get progress
        let progress = transitionImageView.center.y / containerView.frame.height

        let translation = gestureRecognizer.translation(in: containerView)
        transitionImageView.center = CGPoint(x: anchorPoint.x + (movableXAxis ? translation.x : 0), y: anchorPoint.y + translation.y)
        transitionImageView.frame.size = lerpSize(
            fromFrame: finalFrame(for: fromVC),
            currentFrame: previousAnchorFrame!,
            toFrame: finalFrame(for: toVC),
            at: gestureRecognizer.location(in: containerView),
            originPoint: originPoint!
        )

        transitionContext.updateInteractiveTransition(progress)
        viewTransitionAnimator.fractionComplete = progress

        if gestureRecognizer.state == .ended {
            let velocity = gestureRecognizer.velocity(in: fromVC.view)

            transitionContext.finishInteractiveTransition()

            let isReversed = direction(of: velocity) == getDirectionOfCancelling()
            resetImageAnimator(
                endPosition: isReversed ? .start : .end,
                initialVelocity: CGVector(dx: velocity.x / containerView.frame.width, dy: velocity.y / containerView.frame.width))
            viewTransitionAnimator.isReversed = isReversed

            let durationFactor = CGFloat(imageAnimator.duration / viewTransitionAnimator.duration)

            self.previousAnchorFrame = nil
            self.originPoint = nil
            continueAnimationsAfterInteractionEnds(durationFactor: durationFactor)
        }
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return navigationOperation == .push ? 0.5 : 0.25
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

        viewTransitionAnimator = InteractiveHeroAnimatedTransition.getNewViewPropertyAnimator()

        fromVCDelegate.transitionWillStart()
        toVCDelegate.transitionWillStart()

        let toViewAnimationReferences = toVCDelegate.getAnimationReferences()
        let fromViewAnimationReferences = fromVCDelegate.getAnimationReferences()

        toViewAnimationReferences.imageReference.isHidden = true
        fromViewAnimationReferences.imageReference.isHidden = true

        if navigationOperation == .push {
            containerView.addSubview(toView)
            toVC.view.alpha = 0
        } else {
            fromVC.view.alpha = 1
            containerView.insertSubview(toView, belowSubview: fromView)
        }

        if transitionImageView.superview == nil {
            containerView.addSubview(transitionImageView)

            transitionImageView.image = fromViewAnimationReferences.imageReference.image
            transitionImageView.frame = self.finalFrame(for: fromVC)
        }

        resetImageAnimator(endPosition: .end)

        viewTransitionAnimator.addAnimations {
            if self.navigationOperation == .push {
                toVC.view.alpha = 1
            } else {
                fromVC.view.alpha = 0
            }
        }

        viewTransitionAnimator.addCompletion { position in
            self.transitionImageView.removeFromSuperview()
            toViewAnimationReferences.imageReference.isHidden = false
            fromViewAnimationReferences.imageReference.isHidden = false

            transitionContext.completeTransition(position == .end)

            fromVCDelegate.transitionDidEnd()
            toVCDelegate.transitionDidEnd()

            self.transitionContext = nil
        }

        startAnimationsOnInitiallyInteractive()
    }

    func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning) -> any UIViewImplicitlyAnimating {
        return viewTransitionAnimator
    }
}

// MARK: - Animation Math & Generation
extension InteractiveHeroAnimatedTransition {
    static func getNewViewPropertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.85)
    }
}

// MARK: - Helper functions
extension InteractiveHeroAnimatedTransition {
    func isAnimating() -> Bool {
        return transitionContext != nil
    }

    func getDirectionOfCancelling() -> Direction {
        navigationOperation == .push ? .down : .up
    }
}

// MARK: - Animation State Helper Functions
extension InteractiveHeroAnimatedTransition {
    func pauseAnimationsToPrepareForInteraction() {
        viewTransitionAnimator.pauseAnimation()
        imageAnimator.stopAnimation(true)

        isInteractive = true
    }

    func continueAnimationsAfterInteractionEnds(durationFactor: CGFloat) {
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
        guard !wantsInteractiveStart else {
            viewTransitionAnimator.pauseAnimation()
            imageAnimator.pauseAnimation()

            return
        }

        viewTransitionAnimator.startAnimation()
        imageAnimator.startAnimation()
    }

    func resetImageAnimator(endPosition: UIViewAnimatingPosition, initialVelocity: CGVector = .zero) {
        if imageAnimator.state != .inactive {
            imageAnimator.stopAnimation(true)
        }

        imageAnimator = InteractiveHeroAnimatedTransition.getNewViewPropertyAnimator(initialVelocity: initialVelocity)

        guard let toVC = self.transitionContext?.viewController(forKey: .to), let fromVC = self.transitionContext?.viewController(forKey: .from),
            endPosition != .current
        else {
            return
        }

        let finalViewController = endPosition == .end ? toVC : fromVC

        imageAnimator.addAnimations {
            self.transitionImageView.frame = self.finalFrame(for: finalViewController)
        }
    }
}

// MARK: - Frame Calculation Functions
extension InteractiveHeroAnimatedTransition {
    func finalFrame(for viewController: UIViewController) -> CGRect {
        guard let animationDelegate = viewController as? PhotoHeroAnimatorDelegate else {
            return .zero
        }

        return animationDelegate.getAnimationReferences().frame
    }

    func shouldCenterImage(viewController: UIViewController) -> Bool {
        guard let vc = viewController as? PagedPhotoDetailViewController else {
            return false
        }

        return vc.PageType == PhotoPageViewController.self
    }
}
