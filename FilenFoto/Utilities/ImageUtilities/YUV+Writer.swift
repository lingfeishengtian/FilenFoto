//
//  YUV+Writer.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//

import Accelerate

func exportPixelBufferToI420(_ pixelBuffer: CVPixelBuffer, to url: URL) throws {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
    guard planeCount == 3 else {
        throw YUVError.missingPlanes
    }

    FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
    let fileHandle = try FileHandle(forWritingTo: url)
    try fileHandle.truncate(atOffset: 0)

    for plane in 0..<planeCount {
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane) else {
            continue
        }

        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
        let width  = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)

        for row in 0..<height {
            let rowPtr = base.advanced(by: row * bytesPerRow)
            let buffer = UnsafeRawBufferPointer(start: rowPtr, count: width)
            fileHandle.write(Data(buffer))
        }
    }

    try fileHandle.close()
}
