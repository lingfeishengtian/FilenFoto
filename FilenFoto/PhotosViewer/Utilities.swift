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

fileprivate func internalCalculateAnchorPoint(of anchorPoint: CGPoint, in view: UIView) -> CGPoint {
    let coordinateAnchorPoint = CGPoint(x: anchorPoint.x * view.bounds.width, y: anchorPoint.y * view.bounds.height)
    
    return view.convert(coordinateAnchorPoint, from: view)
}
    
func anchorPoint(of view: UIView, in containerView: UIView) -> CGPoint {
    return internalCalculateAnchorPoint(of: view.layer.anchorPoint, in: view)
}

func anchorPoint(of caLayer: CALayer, in containerView: UIView) -> CGPoint {
    return internalCalculateAnchorPoint(of: caLayer.anchorPoint, in: containerView)
}

fileprivate func progress(
    of verticalDelta: CGFloat,
    in view: UIView,
    maximumDeltaScale: CGFloat,
    startingWith maximumValue: CGFloat,
    endingWith minimumValue: CGFloat
) -> CGFloat {
    if minimumValue > maximumValue {
        return minimumValue
    }
    
    let maximumDelta = view.bounds.height * maximumDeltaScale
    let deltaAsAPercent = min(abs(verticalDelta) / maximumDelta, maximumValue)
    let totalScale = maximumValue - minimumValue
    
    return maximumValue - (deltaAsAPercent * totalScale)
}

func alpha(for view: UIView, with verticalDelta: CGFloat) -> CGFloat {
    progress(
        of: verticalDelta,
        in: view,
        maximumDeltaScale: 0.25,
        startingWith: 1,
        endingWith: 0
    )
}

func scale(for view: UIView, with verticalDelta: CGFloat) -> CGFloat {
    progress(
        of: verticalDelta,
        in: view,
        maximumDeltaScale: 0.5,
        startingWith: 1,
        endingWith: 0.5
    )
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

@available(*, deprecated, renamed: "getCenteredAndResizedFrame", message: "Helper functions should not be setting variables")
func resize(imageView: UIImageView, toFit size: CGSize) {
    guard let image = imageView.image else { return }
    
    let minimumZoomScale = minimumZoomScale(for: image.size, in: size)
    imageView.frame.size = CGSize(width: image.size.width * minimumZoomScale, height: image.size.height * minimumZoomScale)
}

@available(*, deprecated, renamed: "getCenteredAndResizedFrame", message: "Helper functions should not be setting variables")
func center(imageView: UIImageView, in frame: CGRect) {
    imageView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
}

@available(*, deprecated, renamed: "getCenteredAndResizedFrame", message: "Helper functions should not be setting variables")
func centerAndResize(imageView: UIImageView, in frame: CGRect) {
    resize(imageView: imageView, toFit: frame.size)
    center(imageView: imageView, in: frame)
}

func getCenteredAndResizedFrame(for imageView: UIImageView, in frame: CGRect) -> CGRect {
    guard let image = imageView.image else { return .zero }
    
    let minimumZoomScale = minimumZoomScale(for: image.size, in: frame.size)
    
    var newFrame = frame
    newFrame.size = CGSize(width: image.size.width * minimumZoomScale, height: image.size.height * minimumZoomScale)
    newFrame.origin = CGPoint(x: frame.width / 2 - newFrame.size.width / 2, y: frame.height / 2 - newFrame.size.height / 2)
    
    return newFrame
}

func lerp(from start: CGFloat, to end: CGFloat, with progress: CGFloat) -> CGFloat {
    return start + (end - start) * progress
}
