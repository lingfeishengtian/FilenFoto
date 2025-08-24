//
//  PhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import AVKit

class PhotoDetailViewController: UIViewController {
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    
    let image: UIImage?
    let animationController: PhotoHeroAnimationController
    let imageIndex: Int /// Purely for tagging purposes during transition
    
    init(animationController: PhotoHeroAnimationController, image: UIImage?, imageIndex: Int) {
        self.image = image
        self.animationController = animationController
        self.imageIndex = imageIndex
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    private lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self

        imageView = UIImageView(frame: self.view.frame)
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = image

        scrollView.addSubview(imageView)

        panGestureRecognizer.delegate = self

        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.view.addSubview(scrollView)
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.view.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        animationController.handleInteractiveTransitionPan(gestureRecognizer, self.navigationController)
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gestureRecognizer.location(in: imageView), view: imageView)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    func getAnimationReferences(in view: UIView) -> AnimationReferences {
        guard let image = self.imageView.image else {
            return AnimationReferences(imageReference: self.imageView, frame: self.imageView.frame)
        }

        let actualImageFrame = AVMakeRect(aspectRatio: image.size, insideRect: view.frame)

        return AnimationReferences(imageReference: self.imageView, frame: actualImageFrame)
    }
}
