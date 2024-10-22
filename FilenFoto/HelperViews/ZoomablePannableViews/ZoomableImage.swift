import PhotosUI
import AVKit
import SwiftUI
import UIKit

fileprivate func assignGestures(
    to view: UIView, in context: (UIViewRepresentableContext<some ZoomablePannableViewContent>)
) {
    let pinchGestureRecognizer = UIPinchGestureRecognizer(
        target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
    let panGestureRecognizer = UIPanGestureRecognizer(
        target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))

    panGestureRecognizer.delegate = context.coordinator

    view.addGestureRecognizer(pinchGestureRecognizer)
    view.addGestureRecognizer(panGestureRecognizer)
}

struct ZoomablePhotoWithDBAsset : ZoomablePannableViewContent {
    @ObservedObject var photoEnvironment: PhotoEnvironment
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    private let thumbnailURL = PhotoVisionDatabaseManager.shared.thumbnailsDirectory


    func makeUIView(context: Context) -> UIView {
        let imageView = UIImageView(image: UIImage(contentsOfFile: thumbnailURL.appending(path: photoEnvironment.selectedDbPhotoAsset!.thumbnailFileName).path))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        assignGestures(to: imageView, in: context)
        imageView.isUserInteractionEnabled = true

        return imageView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? UIImageView else { return }
        if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
            view.image = UIImage(contentsOfFile: thumbnailURL.appending(path: selectedDbPhotoAsset.thumbnailFileName).path)
//#if DEBUG
//            view.image = selectedDbPhotoAsset.localIdentifier.image(withAttributes: [
//                .foregroundColor: UIColor.red,
//                .font: UIFont.systemFont(ofSize: 10.0),
//                .backgroundColor: UIColor.blue,
//            ])
//#endif
        } else {
//            for subView in view.subviews {
//                subView.removeFromSuperview()
//            }
        }
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}

//struct ZoomablePhotoWithDBAsset : ZoomablePannableViewContent {
//    @ObservedObject var photoEnvironment: PhotoEnvironment
//    @Binding var scale: CGFloat
//    @Binding var offset: CGSize
//    var onSwipeUp: () -> Void
//    var onSwipeDown: () -> Void
//    private let thumbnailURL = PhotoVisionDatabaseManager.shared.thumbnailsDirectory
//
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.backgroundColor = .clear
//
//        let imageView = UIImageView(image: UIImage(contentsOfFile: thumbnailURL.appending(path: photoEnvironment.selectedDbPhotoAsset!.thumbnailFileName).path))
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(imageView)
//
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: view.topAnchor),
//            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//        ])
//        
//        
//
//        assignGestures(to: view, in: context)
//        imageView.isUserInteractionEnabled = true
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//        guard let view = uiView.subviews.first as? UIImageView else { return }
//        if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
//            view.image = UIImage(contentsOfFile: thumbnailURL.appending(path: selectedDbPhotoAsset.thumbnailFileName).path)
////#if DEBUG
////            view.image = selectedDbPhotoAsset.localIdentifier.image(withAttributes: [
////                .foregroundColor: UIColor.red,
////                .font: UIFont.systemFont(ofSize: 10.0),
////                .backgroundColor: UIColor.blue,
////            ])
////#endif
//        } else {
////            for subView in view.subviews {
////                subView.removeFromSuperview()
////            }
//        }
//    }
//
//    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
//        ZoomablePannableViewContentCoordinator(self)
//    }
//}

struct ZoomablePhoto: ZoomablePannableViewContent {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    @Binding var image: UIImage

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
        ])

        assignGestures(to: view, in: context)
        imageView.isUserInteractionEnabled = true

        view.sizeToFit()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView.subviews.first as? UIImageView else { return }
        if image != view.image {
            view.image = image
        }
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}

struct ZoomableLivePhoto: ZoomablePannableViewContent {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    @Binding var livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> UIView {
        let view = PHLivePhotoView()
        view.livePhoto = livePhoto

        assignGestures(to: view, in: context)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PHLivePhotoView else { return }
        if livePhoto != view.livePhoto {
            view.livePhoto = livePhoto
        }
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}

protocol ZoomablePannableViewContent: UIViewRepresentable
where Coordinator == ZoomablePannableViewContentCoordinator {
    var scale: CGFloat { get set }
    var offset: CGSize { get set }
    var onSwipeUp: () -> Void { get }
    var onSwipeDown: () -> Void { get }
}

class ZoomablePannableViewContentCoordinator: NSObject, UIGestureRecognizerDelegate {
    var parent: any ZoomablePannableViewContent

    init(_ parent: any ZoomablePannableViewContent) {
        self.parent = parent
    }

    // Allow gestures to be recognized simultaneously
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // Allow all gestures to pass through
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        return true
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            parent.scale = gesture.scale
        case .ended:
            withAnimation {
                self.parent.scale = 1.0
            }
            gesture.scale = 1.0
        default:
            break
        }
    }
    
    private var previous: CGSize? = nil

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            let translation = gesture.translation(in: gesture.view)
            if self.parent.scale == 1.0 {
                let height = translation.y + (previous ?? .zero).height
                parent.offset = CGSize(width: 0, height: height < -300 ? -300 : height)
            } else {
                parent.offset = CGSize(width: translation.x, height: translation.y)
            }
//            parent.offset = .init(width: translation.x, height: parent.offset.height + translation.y)
        case .ended:
            let velocity = gesture.velocity(in: gesture.view)
            print(velocity)
            if velocity.y > 0 {
                parent.onSwipeDown()
            } else {
                parent.onSwipeUp()
            }
//            withAnimation {
//                if parent.offset.width == 0 && parent.scale == 1.0 && parent.offset.height < -10 {
//                    previous = parent.offset
//                } else {
                    self.parent.offset = .zero
//                }
//            }
            gesture.setTranslation(.zero, in: gesture.view)
        default:
            break
        }
    }
}
