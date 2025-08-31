//
//  Utilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

func direction(of delta: CGPoint) -> Direction {
    if UIDevice.current.orientation.isLandscape {
        return delta.x > 0 ? .down : .up
    }

    return delta.y > 0 ? .down : .up
}

func isVerticalMovement(of delta: CGPoint) -> Bool {
    if UIDevice.current.orientation.isLandscape {
        return abs(delta.x) > abs(delta.y)
    }

    return abs(delta.y) > abs(delta.x)
}

private func internalCalculateAnchorPoint(of anchorPoint: CGPoint, in view: UIView) -> CGPoint {
    let coordinateAnchorPoint = CGPoint(x: anchorPoint.x * view.bounds.width, y: anchorPoint.y * view.bounds.height)

    return view.convert(coordinateAnchorPoint, from: view)
}

func anchorPoint(of view: UIView, in containerView: UIView) -> CGPoint {
    return internalCalculateAnchorPoint(of: view.layer.anchorPoint, in: view)
}

func zoomRectForScale(scale: CGFloat, center: CGPoint, view: UIView) -> CGRect {
    var zoomRect = CGRect.zero
    let scrollViewSize = view.bounds.size

    zoomRect.size.width = scrollViewSize.width / scale
    zoomRect.size.height = scrollViewSize.height / scale

    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

    return zoomRect
}

func minimumZoomScale(for imageSize: CGSize, in scrollViewSize: CGSize) -> CGFloat {
    let widthScale = scrollViewSize.width / imageSize.width
    let heightScale = scrollViewSize.height / imageSize.height

    return min(widthScale, heightScale)
}

func centeredAndResizedFrame(for image: UIImage, in frame: CGRect) -> CGRect {
    let minimumZoomScale = minimumZoomScale(for: image.size, in: frame.size)

    var newFrame = frame
    newFrame.size = CGSize(width: image.size.width * minimumZoomScale, height: image.size.height * minimumZoomScale)
    newFrame.origin = CGPoint(x: frame.width / 2 - newFrame.size.width / 2, y: frame.height / 2 - newFrame.size.height / 2)

    return newFrame
}

func lerp(from start: CGFloat, to end: CGFloat, with progress: CGFloat) -> CGFloat {
    return start + (end - start) * progress
}

fileprivate func clampedInvLerp(_ o: CGFloat, _ p: CGFloat, _ m: CGFloat) -> CGFloat {
    if o - m == 0 { return 0 }
    
    return min(max((o - p) / (o - m), 0), 1)
}

/// Mathmatical helper function to linearly interpolate the size of a frame between animation transition frames..
///
/// - Parameters:
///     - fromFrame: Originating frame
///     - currentFrame: Current animation frame
///     - toFrame: Destination frame
///     - position: Current position of the user's pan gesture
///     - originPoint: Start position of the user's pan gesture
///
/// - Returns:
///     - Size after interpolating between the frames with the position
func lerpSize(fromFrame: CGRect, currentFrame: CGRect, toFrame: CGRect, at position: CGPoint, originPoint: CGPoint) -> CGSize {
    let minY = min(fromFrame.midY, toFrame.midY)
    let maxY = max(fromFrame.midY, toFrame.midY)
    
    let outOfBounds = originPoint.y < minY || originPoint.y > maxY
    if outOfBounds {
        let progressOutOfBounds = clampedInvLerp(fromFrame.midY, position.y, toFrame.midY)
        
        return CGSize(
            width: Int(lerp(from: fromFrame.width, to: toFrame.width, with: progressOutOfBounds).rounded()),
            height: Int(lerp(from: fromFrame.height, to: toFrame.height, with: progressOutOfBounds).rounded())
        )
    }
    
    let progressDestination = clampedInvLerp(originPoint.y, position.y, toFrame.midY)
    let progressOrigin = clampedInvLerp(originPoint.y, position.y, fromFrame.midY)
    
    let finalFrame = progressDestination > progressOrigin ? toFrame : fromFrame
    let finalProgress = progressDestination > progressOrigin ? progressDestination : progressOrigin

    return CGSize(
        width: Int(lerp(from: currentFrame.width, to: finalFrame.width, with: finalProgress).rounded()),
        height: Int(lerp(from: currentFrame.height, to: finalFrame.height, with: finalProgress).rounded())
    )
}
