//
//  TestResourceManager.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation

class TestResourceManager {
    static let shared = TestResourceManager()
    private init() {}

    let testBundle = Bundle(for: TestResourceManager.self)

    var testImage: URL {
        let bundleImage = testBundle.url(forResource: "TestImage", withExtension: "HEIC")!
        let destinationURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("HEIC")
        try! FileManager.default.copyItem(at: bundleImage, to: destinationURL)
        return destinationURL
    }

    var hashForTestImage: String = "014cf9c191271bb5b22dcfa95bf72540de06bc67a43af3dca08775fd68295fc6"
    var hashAsDataForTestImage: Data { dataWithHexString(hex: hashForTestImage) }

    var testImageFileSize: UInt64 {
        let attributes = try! FileManager.default.attributesOfItem(atPath: testImage.path)
        return attributes[.size] as! UInt64
    }

    var tempDir: URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FilenFotoTests", isDirectory: true)

        if !FileManager.default.fileExists(atPath: tempDir.path) {
            try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }

        return tempDir
    }
}

private func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()

    while !hex.isEmpty {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let byteString = String(hex[..<subIndex])
        hex = String(hex[subIndex...])

        if let byte = UInt8(byteString, radix: 16) {
            data.append(byte)
        } else {
            fatalError("Invalid hex string")
        }
    }

    return data
}
