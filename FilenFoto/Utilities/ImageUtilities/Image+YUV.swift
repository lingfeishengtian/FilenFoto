//
//  Image+YUV.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//

import Foundation
import UIKit

extension UIImage {
    func exportToRawThumbnail(at url: URL, targetSize: CGSize) throws {
        guard let yuvPixelBuffer = convertUiImageToYUVPixelBuffer(self, targetSize: targetSize) else {
            throw FilenFotoError.yuvError(.failedToGetYUVPixelBuffer)
        }

        do {
            try exportPixelBufferToI420(yuvPixelBuffer, to: url)
        } catch let error as YUVError {
            throw FilenFotoError.yuvError(error)
        } catch {
            print(error)
            throw FilenFotoError.internalError("Unknown error occurred while exporting YUV pixel buffer to I420 file.")
        }
    }

    static func fromRawThumbnail(locatedAt url: URL, targetSize: CGSize) -> UIImage? {
        if let cgImage = cgImageFromI420File(url: url, width: Int(targetSize.width), height: Int(targetSize.height)) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }
}
