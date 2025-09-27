//
//  YUV+Reader.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//

import Foundation
import Accelerate


/// Read an I420 (YUV420 planar: Y, Cb, Cr) raw file and convert to CGImage. The contents of the function run an unsafe operation where memory
/// is manually allocated. However, the memory will be automatically freed by the CGImage on deinit.
/// - Parameters:
///   - url: file URL of raw I420 data
///   - width: image width
///   - height: image height
/// - Returns: UIImage (nil on error)
func cgImageFromI420File(url: URL, width: Int, height: Int) -> CGImage? {
    guard let raw = try? Data(contentsOf: url),
        raw.count >= width * height * 3 / 2
    else {
        return nil
    }

    let halfWidth = width / 2
    let halfHeight = height / 2

    // Split planes
    let yPlane = raw.withUnsafeBytes { ptr -> vImage_Buffer in
        vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: width
        )
    }

    let cbPlane = raw.withUnsafeBytes { ptr -> vImage_Buffer in
        let offset = width * height
        return vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!.advanced(by: offset)),
            height: vImagePixelCount(halfHeight),
            width: vImagePixelCount(halfWidth),
            rowBytes: halfWidth
        )
    }

    let crPlane = raw.withUnsafeBytes { ptr -> vImage_Buffer in
        let offset = width * height + halfWidth * halfHeight
        return vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!.advanced(by: offset)),
            height: vImagePixelCount(halfHeight),
            width: vImagePixelCount(halfWidth),
            rowBytes: halfWidth
        )
    }

    // Destination ARGB buffer
    var destARGB: vImage_Buffer = {
        let rowBytes = width * 4
        let data = UnsafeMutableRawPointer.allocate(
            byteCount: rowBytes * height,
            alignment: ImageUtilitiesConstants.ARGB_BYTE_ALIGNMENT
        )
        return vImage_Buffer(
            data: data,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: rowBytes
        )
    }()

    // Pixel range (full range 0–255)
    var pixelRange = ImageUtilitiesConstants.YUV420P_PIXEL_RANGE

    // Generate conversion info
    var conversionInfo = vImage_YpCbCrToARGB()
    var err = vImageConvert_YpCbCrToARGB_GenerateConversion(
        kvImage_YpCbCrToARGBMatrix_ITU_R_601_4,
        &pixelRange,
        &conversionInfo,
        kvImage420Yp8_Cb8_Cr8,
        kvImageARGB8888,
        vImage_Flags(kvImageNoFlags)
    )
    
    guard err == kvImageNoError else { return nil }

    // Convert YUV420 → ARGB
    var yPlaneVar = yPlane
    var cbPlaneVar = cbPlane
    var crPlaneVar = crPlane
    err = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(
        &yPlaneVar,
        &cbPlaneVar,
        &crPlaneVar,
        &destARGB,
        &conversionInfo,
        nil,
        255,
        vImage_Flags(kvImageNoFlags)
    )
    
    guard err == kvImageNoError else { return nil }

    return makeCGImage(from: destARGB)
}

// Wrap vImage_Buffer directly into a CGImage, skipping the process of re-processing the image as it has already been done during conversion to ARGB
fileprivate func makeCGImage(from buffer: vImage_Buffer) -> CGImage? {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    let rowBytes = buffer.rowBytes

    guard let data = buffer.data else { return nil }

    let provider = CGDataProvider(
        dataInfo: nil,
        data: data,
        size: rowBytes * height,
        releaseData: { _, pointer, _ in
            pointer.deallocate() // Free the pointer just in case
        })!

    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: rowBytes,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
}
