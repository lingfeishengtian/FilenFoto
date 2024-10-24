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
            parent.scale = 2.0
        case .changed:
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        case .ended:
            if view.frame.size.width < view.superview!.frame.size.width
                || view.frame.size.height < view.superview!.frame.size.height
            {
                UIView.animate(withDuration: 0.3) {
                    view.transform = CGAffineTransform.identity
                } completion: { _ in
                    self.parent.scale = 1.0
                }
            }
        default:
            break
        }
    }

    private var previous: CGSize? = nil
    private var isDown: Bool = false
    private var gestureBegan = false

    var previousTranslation: CGSize = .zero

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let view = parent.associatedView

        switch gesture.state {
        case .began, .changed:
            var translation = gesture.translation(in: gesture.view)

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
        default:
            print(
                view.frame.maxX, view.frame.origin.y, view.frame.width, view.superview!.frame.width,
                view.superview!.frame.origin.x)

            var newViewFrame = view.frame

            if view.frame.origin.x > 0 {
                newViewFrame.origin.x = 0
            }
            if view.frame.maxX < view.superview!.frame.width {
                newViewFrame.origin.x = view.superview!.frame.width - view.frame.width
            }

            if view.frame.origin.y > 0 {
                newViewFrame.origin.y = 0
            }

            if view.frame.maxY < view.superview!.frame.height {
                newViewFrame.origin.y = view.superview!.frame.height - view.frame.height
            }

            UIView.animate(withDuration: 0.3) {
                view.frame = newViewFrame

                print(
                    "after", view.frame.maxX, view.frame.origin.y, view.frame.width,
                    view.superview!.frame.width, view.superview!.frame.origin.x)
            }

            if parent.scale == 1.0 {
                // call swipeup or swipedown
                let velocity = gesture.velocity(in: gesture.view)
                if abs(velocity.x) > abs(velocity.y) {
                    return
                }
                if velocity.y > 250 {
                    parent.onSwipeDown()
                } else if velocity.y < -250 {
                    parent.onSwipeUp()
                }
            }

            break
        }
        //        switch gesture.state {
        //        case .began:
        //            isDown = gesture.velocity(in: gesture.view).y > 0
        //            gestureBegan = abs(gesture.velocity(in: gesture.view).y) > 5
        //        case .changed:
        //            if gestureBegan {
        //                let translation = gesture.translation(in: gesture.view)
        //                if self.parent.scale == 1.0 {
        //                    let height = translation.y + (previous ?? .zero).height
        //                    parent.offset = CGSize(width: 0, height: height < -300 ? -300 : height)
        //                    //                print("adding on previous : \(previous?.height) \(translation.y)")
        //                } else {
        //                    parent.offset = CGSize(width: translation.x, height: translation.y)
        //                }
        //            }
        //            //            parent.offset = .init(width: translation.x, height: parent.offset.height + translation.y)
        //            break
        //        case .ended:
        //            let velocity = gesture.velocity(in: gesture.view)
        //            print(velocity)
        //            if velocity.y > 5 {
        //                parent.onSwipeDown()
        //
        //                withAnimation {
        //                    self.parent.offset = .zero
        //                }
        //            } else {
        //                if velocity.y < -5 {
        //                    parent.onSwipeUp()
        //                }
        //            }
        //            //            withAnimation {
        //            //                if parent.offset.width == 0 && parent.scale == 1.0 && parent.offset.height < -10 {
        //            //                    previous = parent.offset
        //            //                } else {
        //            if self.parent.scale != 1.0 || self.parent.offset.height > 0 {
        //                withAnimation {
        //                    self.parent.offset = .zero
        //                }
        //            } else {
        //                if self.parent.offset.height > -200 && self.parent.offset.height < 0 {
        //                    withAnimation {
        //                        self.parent.offset.height = -200
        //                    }
        //                }
        //                previous = self.parent.offset
        //            }
        //            //                }
        //            //            }
        //            gesture.setTranslation(.zero, in: gesture.view)
        //        default:
        //            break
        //        }
    }
}
