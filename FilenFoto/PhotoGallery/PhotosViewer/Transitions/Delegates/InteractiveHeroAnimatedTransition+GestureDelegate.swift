//
//  InteractiveHeroAnimatedTransition+Helper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/29/25.
//

import Foundation
import UIKit

extension InteractiveHeroAnimatedTransition: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
