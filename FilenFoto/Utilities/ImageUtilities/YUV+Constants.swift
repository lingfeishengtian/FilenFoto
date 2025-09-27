//
//  YUV+Constants.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/24/25.
//
import Accelerate

struct ImageUtilitiesConstants {
    static let ARGB_BYTE_ALIGNMENT = 64
    static let YUV420P_PIXEL_RANGE = vImage_YpCbCrPixelRange(
        Yp_bias: 16,
        CbCr_bias: 128,
        YpRangeMax: 235,
        CbCrRangeMax: 240,
        YpMax: 255,
        YpMin: 0,
        CbCrMax: 255,
        CbCrMin: 1)
}
