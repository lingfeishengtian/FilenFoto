//
//  GestureCoordinator.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/23/24.
//

import SwiftUI
import UIKit

protocol ZoomablePannable {
    var scale: CGFloat { get set }
    var offset: CGSize { get set }
    var scrolling: Bool { get set }
    var onSwipeUp: () -> Void { get }
    var onSwipeDown: () -> Void { get }
    var associatedView: UIView { get set }
}

protocol ZoomablePannableViewContent: UIViewRepresentable, ZoomablePannable
where Coordinator == ZoomablePannableViewContentCoordinator {
}

protocol ZoomablePannableViewControllerContent: UIViewControllerRepresentable, ZoomablePannable
where Coordinator == ZoomablePannableViewContentCoordinator {
}

class ZoomablePannableViewContentCoordinator: NSObject, UIGestureRecognizerDelegate {
    var parent: any ZoomablePannable

    init(_ parent: any ZoomablePannable) {
        self.parent = parent
    }

    static func assignGestures(
        to view: UIView, in coordinator: ZoomablePannableViewContentCoordinator
    ) {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(
            target: coordinator, action: #selector(coordinator.handlePinch(_:)))
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: coordinator, action: #selector(coordinator.handlePan(_:)))
        let doubleTapGestureRecognizer = UITapGestureRecognizer(
            target: coordinator, action: #selector(coordinator.handDoubleTap(_:)))

        panGestureRecognizer.delegate = coordinator
        pinchGestureRecognizer.delegate = coordinator
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.delegate = coordinator

        view.addGestureRecognizer(pinchGestureRecognizer)
        view.addGestureRecognizer(panGestureRecognizer)
        view.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    // Allow gestures to be recognized simultaneously
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // Allow all gestures to pass through
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        return true
    }

    @objc func handDoubleTap(_ gesture: UITapGestureRecognizer) {
        let view = parent.associatedView

        if !isPinching {
            withAnimation {
                parent.scale = 2.0
            }
            isPinching = true
            UIView.animate(withDuration: 0.3) {
                view.transform = view.transform.scaledBy(x: 2.0, y: 2.0)
            }
        } else {
            isPinching = false
            
            withAnimation {
                parent.scale = 1.0
            }
            UIView.animate(withDuration: 0.3) {
                view.transform = CGAffineTransform.identity
            }
        }
    }

    private var isPinching: Bool = false
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        //        switch gesture.state {
        //        case .began, .changed:
        //            parent.scale = gesture.scale
        //        case .ended:
        //            withAnimation {
        //                self.parent.scale = 1.0
        //            }
        //            gesture.scale = 1.0
        //        default:
        //            break
        //        }
        let view = parent.associatedView

        switch gesture.state {
        case .began:
            isPinching = true
            withAnimation {
                parent.scale = 2.0
            }
        case .changed:
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        case .ended:
            if view.frame.size.width < view.superview!.frame.size.width
                || view.frame.size.height < view.superview!.frame.size.height
            {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                }
                
                isPinching = false
                
                withAnimation {
                    self.parent.scale = 1.0
                }
            }
        default:
            break
        }
    }

    enum ScrollState {
        case scrollDown
        case scrollUp
        case normalPan
        case cancelScroll
    }
    private var scrollState: ScrollState = .normalPan
    private var gestureBegan = false
    private let minVelocity: CGFloat = 250

    var previousTranslation: CGSize = .zero

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let view = parent.associatedView

        switch gesture.state {
        case .began:
            let velocity = gesture.velocity(in: gesture.view)

            if !isPinching {
                // call swipeup or swipedown
                if abs(velocity.x) > abs(velocity.y) {
                    scrollState = .cancelScroll
                    return
                }
                if velocity.y > minVelocity {
                    scrollState = .scrollDown

                    withAnimation {
                        self.parent.scale = 0.5
                        self.parent.scrolling = true
                    }

                    UIView.animate(withDuration: 0.3) {
                        view.transform = view.transform.scaledBy(x: 0.5, y: 0.5)
                    }
                } else if velocity.y < -minVelocity {
                    scrollState = .scrollUp

                    withAnimation {
                        self.parent.scrolling = true
                    }
                } else {
                    scrollState = .cancelScroll
                }
            } else {
                scrollState = .normalPan

                withAnimation {
                    self.parent.scrolling = true
                }
            }
        case .changed:
            if scrollState == .cancelScroll {
                return
            }
            var translation = gesture.translation(in: gesture.view)

            if scrollState == .normalPan {
                // if translation is out of bounds, reduce it until it can be moved
                if view.frame.origin.x + translation.x > 0 {
                    translation.x = -view.frame.origin.x
                }
                if view.frame.maxX + translation.x < view.superview!.frame.width {
                    translation.x = view.superview!.frame.width - view.frame.maxX
                }

                if view.frame.origin.y + translation.y > 0 {
                    translation.y = -view.frame.origin.y
                }

                if view.frame.maxY + translation.y < view.superview!.frame.height {
                    translation.y = view.superview!.frame.height - view.frame.maxY
                }

                view.transform = view.transform.translatedBy(x: translation.x, y: translation.y)
                gesture.setTranslation(.zero, in: gesture.view)
            } else if scrollState == .scrollDown {
                // center of user touch
                let center = CGPoint(
                    x: view.frame.origin.x - view.frame.width / 4,  // scaled by 0.5
                    y: view.frame.origin.y - view.frame.height / 4)  // scaled by 0.5

                // TODO: FIX doesn't always snap back to top
                if view.frame.midY < (view.superview?.frame.midY ?? 900) / 3 {
                    scrollState = .scrollUp

                    self.parent.scale = 1.0
                    self.parent.offset = .zero

                    UIView.animate(withDuration: 0.3) {
                        view.transform = CGAffineTransform.identity
                        view.transform = view.transform.translatedBy(
                            x: 0, y: translation.y - center.y)
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        // transform the view to the center of the user touch
                        view.transform = view.transform.translatedBy(
                            x: translation.x - center.x, y: translation.y - center.y)
                        self.parent.offset = .init(
                            width: 0, height: view.frame.origin.y + translation.y)
                    }
                }
            } else if scrollState == .scrollUp {
                // slowly scale up to 1.5 and slowly offset x (should depend on distance from 0)
                let maximumNegation = -view.frame.height / 3
                let maximumScaleMagnitude = 0.3
                var translationY = translation.y

                if view.frame.minY + translation.y < maximumNegation {
                    translationY = maximumNegation
                }

                if view.frame.minY + translation.y > 0 {
                    scrollState = .scrollDown

                    DispatchQueue.main.async {
                        self.parent.scale = 0.5
                    }

                    UIView.animate(withDuration: 0.3) {
                        view.transform = view.transform.scaledBy(x: 0.5, y: 0.5)
                        view.transform = view.transform.translatedBy(x: 0, y: translationY)
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        view.transform = CGAffineTransform.identity
                        //                    view.transform = view.transform.scaledBy(x: 1 + (translationY / maximumNegation) * maximumScaleMagnitude, y: 1 + (translationY / maximumNegation) * maximumScaleMagnitude)
                        view.transform = view.transform.translatedBy(x: 0, y: translationY)
                    }
                }
            }

        default:
            withAnimation {
                self.parent.scrolling = false
                self.parent.offset = .zero
                if !isPinching {
                    self.parent.scale = 1.0
                }
            }
            if scrollState == .cancelScroll {
                return
            }
            print(
                view.frame.maxX, view.frame.origin.y, view.frame.width, view.superview!.frame.width,
                view.superview!.frame.origin.x)

            let oldFrame = view.frame
            var newViewFrame = view.frame

            if view.frame.origin.x > 0 {
                newViewFrame.origin.x = 0
            }
            if view.frame.maxX < view.superview!.frame.width {
                newViewFrame.origin.x = view.superview!.frame.width - view.frame.width
            }

            if view.frame.origin.y > 0 && scrollState != .scrollUp {
                newViewFrame.origin.y = 0
            }

            if view.frame.maxY < view.superview!.frame.height {
                newViewFrame.origin.y = view.superview!.frame.height - view.frame.height
            }

            let velocity = gesture.velocity(in: gesture.view)

            if scrollState == .scrollDown {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                }
            } else if scrollState == .scrollUp {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                    self.parent.onSwipeUp()
                }
            }

            if self.parent.scale == 1.0 || scrollState == .scrollDown {
                // call swipeup or swipedown
                if abs(velocity.x) > abs(velocity.y) {
                    return
                }
                if velocity.y > 250 && scrollState == .scrollDown && oldFrame.midY > 50 {
                    self.parent.onSwipeDown()
                }
                //                else if velocity.y < -250 && scrollState != .scrollDown {
                //                    view.frame = newViewFrame
                //
                //                    self.parent.onSwipeUp()
                //                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    view.frame = newViewFrame
                    print(
                        "after", view.frame.maxX, view.frame.origin.y, view.frame.width,
                        view.superview!.frame.width, view.superview!.frame.origin.x)
                }
            }
            break
        }
    }
}
