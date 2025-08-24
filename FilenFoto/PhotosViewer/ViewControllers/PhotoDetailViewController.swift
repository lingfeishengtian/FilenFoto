//
//  PhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoDetailViewController: UIViewController {
    var imageView: UIImageView!
    var image: UIImage?
    var animationController: PhotoHeroAnimationController!

    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView = UIImageView(frame: self.view.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = image

        panGestureRecognizer.delegate = self

        self.view.backgroundColor = .white  // TODO: Change

        self.view.addSubview(imageView)
        self.view.addGestureRecognizer(panGestureRecognizer)
    }

    func configure(with image: UIImage) {
        self.image = image

        if isViewLoaded {
            imageView.image = image
        }
    }

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        animationController.handleInteractiveTransitionPan(gestureRecognizer, self.navigationController)
    }
}
