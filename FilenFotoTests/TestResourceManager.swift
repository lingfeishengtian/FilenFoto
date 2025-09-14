//
//  TestResourceManager.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation

class TestResourceManager {
    static let shared = TestResourceManager()
    private init() { }
    
    let testBundle = Bundle(for: TestResourceManager.self)
    
    var testImage: URL {
        let bundleImage = testBundle.url(forResource: "TestImage", withExtension: "HEIC")!
        let destinationURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("HEIC")
        try! FileManager.default.copyItem(at: bundleImage, to: destinationURL)
        return destinationURL
    }
    
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
