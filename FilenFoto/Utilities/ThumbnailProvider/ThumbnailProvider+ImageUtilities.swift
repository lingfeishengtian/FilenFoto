//
//  ThumbnailProvider+ImageUtilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import Foundation
import UIKit

let JPEG_COMPRESSION_QUALITY: CGFloat = 0.8

extension ThumbnailProvider {
    func compressedPixelSize(pixelHeight: Int64, pixelWidth: Int64) -> CGSize {
        let maxDimension: CGFloat = 200.0
        let size = CGSize(width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        return newSize
    }

    func compressImageToJpeg(_ image: UIImage) -> Data? {
        let newSize = compressedPixelSize(pixelHeight: Int64(image.size.height), pixelWidth: Int64(image.size.width))

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.jpegData(compressionQuality: JPEG_COMPRESSION_QUALITY)
    }
}
