//
//  FullImageOverlay.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/15/24.
//

import Foundation
import UIKit
import SwiftUI

class ImageDetailViewSheetController: UIViewController {
}

@IBDesignable
class FullImageOverlay: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var mainImageViewer: UICollectionView!
    @IBOutlet weak var imageInfoTopBar: UIView!
    @IBOutlet weak var imageDetailView: UIView!
    @IBOutlet weak var imageScrubber: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    let hostingController = UIHostingController(rootView: TestView())
    var spaceAfterImageViewer: CGFloat = 0
    
    private func commonInit() {
        Bundle.main.loadNibNamed("FullImageOverlay", owner: self, options: nil)
        contentView.fixInView(self)
        contentView.backgroundColor = .red
        
        imageInfoTopBar.addSubview(hostingController.view)
        hostingController.view.fixInView(imageInfoTopBar)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        mainImageViewer.addGestureRecognizer(panGesture)
        imageDetailView.addSubview(hostingController.view)
        hostingController.view.fixInView(imageDetailView)
        
        // imageDetailView off screen
        imageDetailView.frame.origin.y = UIScreen.main.bounds.height
        
        spaceAfterImageViewer = UIScreen.main.bounds.height - mainImageViewer.frame.maxY
        imageDetailView.frame.origin.y = UIScreen.main.bounds.height
    }
    
    enum SwipeDirection {
        case up
        case down
    }
    
    func imageDetailViewScrollEvent(translation: CGPoint) {
        mainImageViewer.transform = CGAffineTransform(translationX: 0, y: translation.y)
        imageDetailView.layer.opacity = Float(abs(translation.y) / 50)
        let detailTranslation = UIScreen.main.bounds.height + translation.y
        if detailTranslation >= UIScreen.main.bounds.height {
            self.imageDetailView.frame.origin.y = UIScreen.main.bounds.height
            UIView.animate(withDuration: 0.4) {
                self.imageScrubber.layer.opacity = 1
            }
        } else {
            if self.imageDetailView.frame.origin.y == UIScreen.main.bounds.height {
                UIView.animate(withDuration: 0.2) {
                    self.imageDetailView.frame.origin.y = detailTranslation - self.spaceAfterImageViewer
                }
            } else {
                self.imageDetailView.frame.origin.y = detailTranslation - self.spaceAfterImageViewer
            }
            UIView.animate(withDuration: 0.4) {
                self.imageScrubber.layer.opacity = 0
            }
        }
    }
    
    func resetTransform() {
        UIView.animate(withDuration: 0.2) {
            self.mainImageViewer.transform = .identity
            self.imageDetailView.layer.opacity = 0
            self.imageScrubber.layer.opacity = 1
            self.imageDetailView.frame.origin.y = UIScreen.main.bounds.height
        }
    }
    
    @objc func onPanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let velocity = sender.velocity(in: self)
        
        switch sender.state {
        case .began, .changed:
            imageDetailViewScrollEvent(translation: translation)
        default:
            resetTransform()
        }
    }
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

struct FullImageOverlayUIView: UIViewRepresentable {
    func makeUIView(context: Context) -> FullImageOverlay {
        let view = FullImageOverlay()
        return view
    }
    
    func updateUIView(_ uiView: FullImageOverlay, context: Context) {
    }
}

struct TestView : View{
    var body: some View {
        Text("Hello, World! Nyo")
        Spacer()
    }
}

#Preview {
    FullImageOverlayUIView()
}
