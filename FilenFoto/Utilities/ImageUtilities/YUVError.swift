//
//  YUVError.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//

import Foundation

enum YUVError: LocalizedError {
    case missingPlanes
    case failedToGetYUVPixelBuffer

    var errorDescription: LocalizedStringResource? {
        switch self {
        case .missingPlanes:
            return "Missing YUV planes."
        case .failedToGetYUVPixelBuffer:
            return "Failed to get YUV pixel buffer."
        }
    }
}
