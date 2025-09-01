//
//  PhotoDetailView+ScrollViewDelegate.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

extension ScrollableImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        for gestureRecognizer in (parent as! UIPageViewController).gestureRecognizers {
            gestureRecognizer.isEnabled = false
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        for gestureRecognizer in (parent as! UIPageViewController).gestureRecognizers {
            gestureRecognizer.isEnabled = true
        }
    }
}
