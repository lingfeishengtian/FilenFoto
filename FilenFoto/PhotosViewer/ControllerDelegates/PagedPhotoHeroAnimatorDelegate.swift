//
//  PagedPhotoHeroAnimatorDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//


import Foundation
import UIKit

protocol PagedPhotoHeroAnimatorDelegate: AnyObject  {
    /// The Animatior will always assume the coordinates that you pass are in the coordinate space of the view. Therefore, you should convert the coordinates if needed.
    func getAnimationReferences(in view: UIView) -> AnimationReferences
}
