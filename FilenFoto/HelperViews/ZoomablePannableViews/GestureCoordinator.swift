//
//  GestureCoordinator.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/23/24.
//

import SwiftUI
import UIKit

protocol ZoomablePannable {
    var associatedView: UIView { get set }
    var isPinching: Bool { get set }
}

protocol ZoomablePannableViewContent: UIViewRepresentable, ZoomablePannable
where Coordinator == ZoomablePannableViewContentCoordinator {
}

protocol ZoomablePannableViewControllerContent: UIViewControllerRepresentable, ZoomablePannable
where Coordinator == ZoomablePannableViewContentCoordinator {
}

class ZoomablePannableViewContentCoordinator: NSObject, UIGestureRecognizerDelegate {
    var parent: ZoomablePannable
    var urlAssociated: [URL] = []
    
    init(_ parent: some ZoomablePannable) {
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
        if let pinch = gestureRecognizer as? UIPinchGestureRecognizer {
            return true
        } else if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return parent.isPinching
        } else {
            return true
        }
    }

    @objc func handDoubleTap(_ gesture: UITapGestureRecognizer) {
        let view = parent.associatedView

        if !parent.isPinching {
            parent.isPinching = true
            UIView.animate(withDuration: 0.3) {
                view.transform = view.transform.scaledBy(x: 2.0, y: 2.0)
            }
        } else {
            parent.isPinching = false
            
            UIView.animate(withDuration: 0.3) {
                view.transform = CGAffineTransform.identity
            }
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let view = parent.associatedView

        switch gesture.state {
        case .began:
            parent.isPinching = true
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
                
                parent.isPinching = false
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
    private let minVelocity: CGFloat = 20

    var previousTranslation: CGSize = .zero

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let view = parent.associatedView

        switch gesture.state {
        case .began:
            let velocity = gesture.velocity(in: gesture.view)

            if !parent.isPinching {
                return;
                
                // call swipeup or swipedown
                if abs(velocity.x) > abs(velocity.y) {
                    scrollState = .cancelScroll
                    return
                }
                if velocity.y > minVelocity {
                    scrollState = .scrollDown

                    UIView.animate(withDuration: 0.3) {
                        view.transform = view.transform.scaledBy(x: 0.5, y: 0.5)
                    }
                } else if velocity.y < -minVelocity {
                    scrollState = .scrollUp

                } else {
                    scrollState = .cancelScroll
                }
            } else {
                scrollState = .normalPan

            }
        case .changed:
            if scrollState == .cancelScroll {
                return
            }
            var translation = gesture.translation(in: gesture.view)
            print("translationY", translation.y)

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
                return
                // center of user touch
                let center = CGPoint(
                    x: view.frame.origin.x - view.frame.width / 4,  // scaled by 0.5
                    y: view.frame.origin.y - view.frame.height / 4)  // scaled by 0.5

                // TODO: FIX doesn't always snap back to top
//                if view.frame.midY < (view.superview?.frame.midY ?? 900) / 3 {
                if translation.y < -100 {
                    scrollState = .scrollUp

//                    self.parent.offset = .zero

                    UIView.animate(withDuration: 0.3) {
                        view.transform = CGAffineTransform.identity
//                        view.transform = view.transform.translatedBy(
//                            x: 0, y: translation.y - center.y)
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        // transform the view to the center of the user touch
                        view.transform = view.transform.translatedBy(
                            x: translation.x - center.x, y: translation.y - center.y)
                    }
                }
            } else if scrollState == .scrollUp {
                return
                // slowly scale up to 1.5 and slowly offset x (should depend on distance from 0)
                let maximumNegation = -view.frame.height / 3
                let maximumScaleMagnitude = 0.3
                var translationY = translation.y

                print("translationY", translationY)
                if translation.y < maximumNegation {
                    translationY = maximumNegation
                }
            }

        default:
            if scrollState != .normalPan {
                return
            }
            let velocity = gesture.velocity(in: gesture.view)
            
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


            if scrollState == .scrollDown {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                }
            } else if scrollState == .scrollUp && velocity.y < -minVelocity {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                }
            }

//            if self.parent.scale == 1.0 || scrollState == .scrollDown {
//                // call swipeup or swipedown
//                if abs(velocity.x) > abs(velocity.y) {
//                    return
//                }
//                if velocity.y > 250 && scrollState == .scrollDown && oldFrame.midY > 50 {
//                    self.parent.onSwipeDown()
//                    self.parent.scrolling = true
//                }
//                //                else if velocity.y < -250 && scrollState != .scrollDown {
//                //                    view.frame = newViewFrame
//                //
//                //                    self.parent.onSwipeUp()
//                //                }
//            } else {
//                UIView.animate(withDuration: 0.3) {
//                    view.frame = newViewFrame
//                    print(
//                        "after", view.frame.maxX, view.frame.origin.y, view.frame.width,
//                        view.superview!.frame.width, view.superview!.frame.origin.x)
//                }
//            }
            break
        }
    }
}
