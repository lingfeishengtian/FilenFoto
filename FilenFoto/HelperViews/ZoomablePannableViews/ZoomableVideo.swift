import SwiftUI
import AVFoundation
import AVKit

struct ZoomableVideo: UIViewControllerRepresentable {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    var video: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = video
        playerViewController.showsPlaybackControls = true

        // Add gesture recognizers to the playerViewController's view
        assignGestures(to: playerViewController.view, in: context)

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = video
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func assignGestures(to view: UIView, in context: Context) {
        // Add pinch gesture recognizer
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        pinchGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(pinchGestureRecognizer)

        // Add pan gesture recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        panGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(panGestureRecognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ZoomableVideo

        init(_ parent: ZoomableVideo) {
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
        private var isDown: Bool = false

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                isDown = gesture.velocity(in: gesture.view).y > 0
            case .changed:
                let translation = gesture.translation(in: gesture.view)
                if self.parent.scale == 1.0 {
                    let height = translation.y + (previous ?? .zero).height
                    parent.offset = CGSize(width: 0, height: height < -300 ? -300 : height)
    //                print("adding on previous : \(previous?.height) \(translation.y)")
                } else {
                    parent.offset = CGSize(width: translation.x, height: translation.y)
                }
    //            parent.offset = .init(width: translation.x, height: parent.offset.height + translation.y)
                break
            case .ended:
                let velocity = gesture.velocity(in: gesture.view)
                print(velocity)
                if velocity.y > 0 {
                    parent.onSwipeDown()
                    
                    withAnimation {
                        self.parent.offset = .zero
                    }
                } else {
                    parent.onSwipeUp()
                }
    //            withAnimation {
    //                if parent.offset.width == 0 && parent.scale == 1.0 && parent.offset.height < -10 {
    //                    previous = parent.offset
    //                } else {
                if self.parent.scale != 1.0 || self.parent.offset.height > 0 {
                    withAnimation {
                        self.parent.offset = .zero
                    }
                } else {
                    if self.parent.offset.height > -200 && self.parent.offset.height < 0 {
                        withAnimation {
                            self.parent.offset.height = -200
                        }
                    }
                    previous = self.parent.offset
                }
    //                }
    //            }
                gesture.setTranslation(.zero, in: gesture.view)
            default:
                break
            }
        }
    }
}
