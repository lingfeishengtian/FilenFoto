import SwiftUI
import AVKit

struct ZoomableVideo: ZoomablePannableViewControllerContent {
    @Binding var isPinching: Bool
    var videoURL: URL
    @State var associatedView: UIView = UIView()
    let videoDelegate: ZoomableVideoPlaybackDelegate

    init(isPinching: Binding<Bool>, videoURL: URL) {
        self._isPinching = isPinching
        self.videoURL = videoURL
        self.videoDelegate = ZoomableVideoPlaybackDelegate(isPinching: isPinching)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = UIScrollView()
        view.backgroundColor = .clear

        let playerViewController = AVPlayerViewController()
        playerViewController.player = AVPlayer(url: videoURL)
        
        context.coordinator.urlAssociated.append(videoURL)
        
        playerViewController.view.backgroundColor = .clear
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(playerViewController.view)
        
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.sizeToFit()

        DispatchQueue.main.async {
            self.associatedView = playerViewController.view
        }
        
        ZoomablePannableViewContentCoordinator.assignGestures(to: playerViewController.view, in: context.coordinator)
        
        playerViewController.view.isUserInteractionEnabled = true
        playerViewController.delegate = videoDelegate

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if context.coordinator.urlAssociated.contains(videoURL) {
            return
        }
        
        context.coordinator.urlAssociated.removeAll()
        context.coordinator.urlAssociated.append(videoURL)
        
        uiViewController.player = AVPlayer(url: videoURL)
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}

class ZoomableVideoPlaybackDelegate: NSObject, AVPlayerViewControllerDelegate {
    @Binding var isPinching: Bool
    
    init(isPinching: Binding<Bool>) {
        self._isPinching = isPinching
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
        isPinching = true
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
        isPinching = false
    }
}
