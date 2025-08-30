//
//  DetailedPhotoViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import AVKit
import Foundation
import SwiftUI
import UIKit
import os


let IMAGE_PERCENT_OF_SCREEN: CGFloat = 0.5

class DetailedPhotoViewController: FFParentImageViewController {
    private let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "DetailedPhotoViewController")

    var swiftUIView: UIHostingController<AnyView>!
    lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

    func calculateImageFrame() -> CGRect {
        CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height * IMAGE_PERCENT_OF_SCREEN)
    }

    func calculateSwiftUIFrame() -> CGRect {
        CGRect(
            x: 0, y: view.frame.height * IMAGE_PERCENT_OF_SCREEN, width: view.frame.width, height: view.frame.height * (1 - IMAGE_PERCENT_OF_SCREEN))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView = UIImageView(frame: calculateImageFrame())
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = image

        if let detailedViewBuilder = getDetailedPhotoBuilder(), let image {
            swiftUIView = UIHostingController(rootView: detailedViewBuilder(image))
        } else {
            swiftUIView = UIHostingController(rootView: AnyView(EmptyView()))
            logger.error("No detailed view builder or image available")
        }

        swiftUIView.view.frame = calculateSwiftUIFrame()
        swiftUIView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        panGestureRecognizer.delegate = self
        

        self.view.addSubview(imageView)
        self.view.addSubview(swiftUIView.view)
        self.view.addGestureRecognizer(panGestureRecognizer)
    }

    override func getAnimationReferences(in view: UIView) -> AnimationReferences {
        return AnimationReferences(imageReference: self.imageView, frame: self.view.convert(calculateImageFrame(), to: view))
    }

    // MARK: - Gesture Recognizers
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            animationController.beganTransition(initiallyInteractive: true)
            self.navigationController?.popViewController(animated: true)
            self.animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
        default:
            self.animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
        }
    }
}
