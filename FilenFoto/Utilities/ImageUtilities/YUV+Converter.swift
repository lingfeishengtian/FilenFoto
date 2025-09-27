//
//  YUV+Writer.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//

@preconcurrency import Accelerate
import UIKit

func convertUiImageToYUVPixelBuffer(_ uiImage: UIImage, targetSize: CGSize? = nil) -> CVPixelBuffer? {
    guard let argbPixelBuffer = uiImageToARGBPixelBuffer(uiImage, targetSize: targetSize) else { return nil }
    return argbPixelBufferToYUV420PixelBuffer(argbPixelBuffer)
}

extension UIImage {
    fileprivate func normalizedCGImage() -> CGImage? {
        if imageOrientation == .up {
            return self.cgImage
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        return normalized
    }
}

// MARK: - UIImage -> ARGB CVPixelBuffer (with optional targetSize)
private func uiImageToARGBPixelBuffer(_ image: UIImage, targetSize: CGSize? = nil) -> CVPixelBuffer? {
    guard let cgImage = image.normalizedCGImage() else { return nil }

    let width = Int(targetSize?.width ?? CGFloat(cgImage.width))
    let height = Int(targetSize?.height ?? CGFloat(cgImage.height))
    
    // Must be divisible by 2 for ARGB to convert well into YUV420 or else we get color artifacts
    if width % 2 != 0 || height % 2 != 0 {
        return nil
    }

    let attrs: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32ARGB,  // ARGB8888 pixel format
        attrs as CFDictionary,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

    // Create CGContext that writes directly into the pixel buffer’s memory
    guard
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue  // ARGB (skip alpha, 8 bits each)
        )
    else { return nil }

    // Draw the image into the buffer (resizing if targetSize provided)
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    context.interpolationQuality = .high

    context.draw(cgImage, in: rect)
    
    return buffer
}

// MARK: - Convert ARGB CVPixelBuffer -> new YUV420 CVPixelBuffer
private func argbPixelBufferToYUV420PixelBuffer(_ srcPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    let width = CVPixelBufferGetWidth(srcPixelBuffer)
    let height = CVPixelBufferGetHeight(srcPixelBuffer)

    let attrs: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]

    var yuvBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_420YpCbCr8Planar,
        attrs as CFDictionary,
        &yuvBuffer
    )

    guard status == kCVReturnSuccess, let destBuffer = yuvBuffer else { return nil }

    CVPixelBufferLockBaseAddress(srcPixelBuffer, .readOnly)
    CVPixelBufferLockBaseAddress(destBuffer, [])

    defer {
        CVPixelBufferUnlockBaseAddress(srcPixelBuffer, .readOnly)
        CVPixelBufferUnlockBaseAddress(destBuffer, [])
    }

    guard let srcBase = CVPixelBufferGetBaseAddress(srcPixelBuffer) else { return nil }

    var srcBuffer = vImage_Buffer(
        data: srcBase,
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    )

    guard
        let yPlane = CVPixelBufferGetBaseAddressOfPlane(destBuffer, 0),
        let uPlane = CVPixelBufferGetBaseAddressOfPlane(destBuffer, 1),
        let vPlane = CVPixelBufferGetBaseAddressOfPlane(destBuffer, 2)
    else { return nil }

    var destPlanes = [
        vImage_Buffer(
            data: yPlane,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: CVPixelBufferGetBytesPerRowOfPlane(destBuffer, 0)
        ),
        vImage_Buffer(
            data: uPlane,
            height: vImagePixelCount(height / 2),
            width: vImagePixelCount(width / 2),
            rowBytes: CVPixelBufferGetBytesPerRowOfPlane(destBuffer, 1)
        ),
        vImage_Buffer(
            data: vPlane,
            height: vImagePixelCount(height / 2),
            width: vImagePixelCount(width / 2),
            rowBytes: CVPixelBufferGetBytesPerRowOfPlane(destBuffer, 2)
        ),
    ]

    // TODO: Make this a constant
    var pixelRange = ImageUtilitiesConstants.YUV420P_PIXEL_RANGE

    var conversionInfo = vImage_ARGBToYpCbCr()
    var error = vImageConvert_ARGBToYpCbCr_GenerateConversion(
        kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4,
        &pixelRange,
        &conversionInfo,
        kvImageARGB8888,
        kvImage420Yp8_Cb8_Cr8,
        vImage_Flags(kvImageNoFlags)
    )

    guard error == kvImageNoError else { return nil }

    error = vImageConvert_ARGB8888To420Yp8_Cb8_Cr8(
        &srcBuffer,
        &destPlanes[0],
        &destPlanes[1],
        &destPlanes[2],
        &conversionInfo,
        nil,
        vImage_Flags(kvImageNoFlags)
    )

    guard error == kvImageNoError else { return nil }
    return destBuffer
}
