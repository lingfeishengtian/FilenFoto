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

func anchorPoint(of view: UIView, in containerView: UIView) -> CGPoint {
    let anchorPoint = view.anchorPoint
    let coordinateAnchorPoint = CGPoint(x: anchorPoint.x * view.bounds.width, y: anchorPoint.y * view.bounds.height)
    
    return containerView.convert(coordinateAnchorPoint, from: view)
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
