//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroInteractiveTransition = InteractiveHeroAnimatedTransition()
    let detailedInfoTransition = DetailedInfoTransition()
    let detailedInfoInteractiveTransition = DetailedInfoInteractiveTransition()
    var isInteractive = false
    
    var navigatorControllerPanGesture: UIPanGestureRecognizer!
    
    init(navigatorControllerPanGesture: UIPanGestureRecognizer) {
        super.init()
        
//        self.navigatorControllerPanGesture = navigatorControllerPanGesture
//        self.navigatorControllerPanGesture.delegate = self
//        self.navigatorControllerPanGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
//        print("Pan gesture translation: \(translation)")
    }
}
