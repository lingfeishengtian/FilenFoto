//
//  ThumbnailProvider+ImageUtilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import Foundation
import UIKit

extension ThumbnailProvider {
    static let MAX_COMPRESSED_DIMENSION: CGFloat = 350

    nonisolated func compressedPixelSize(pixelHeight: Int64, pixelWidth: Int64) -> CGSize {
        let maxDimension: CGFloat = ThumbnailProvider.MAX_COMPRESSED_DIMENSION
        let size = CGSize(width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if aspectRatio > 1 {
            let height = floor(maxDimension / aspectRatio).roundedToEven
            newSize = CGSize(width: maxDimension, height: height)
        } else {
            let width = floor(maxDimension * aspectRatio).roundedToEven
            newSize = CGSize(width: width, height: maxDimension)
        }

        return newSize
    }
}

fileprivate extension CGFloat {
    /// Rounds the CGFloat to the nearest multiple of `divisor` treating it as an integer
    func roundedToNearest(_ divisor: CGFloat) -> CGFloat {
        guard divisor != 0 else { return self }
        let intValue = Int(self.rounded())  // round to nearest integer first
        let roundedInt = (intValue + Int(divisor) / 2) / Int(divisor) * Int(divisor)
        return CGFloat(roundedInt)
    }

    /// Shortcut for rounding to nearest even number
    var roundedToEven: CGFloat {
        return self.roundedToNearest(2)
    }
}
