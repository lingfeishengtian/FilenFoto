//
//  UtilitiesTest.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/16/25.
//

import Foundation
import Testing

@testable import FilenFoto

struct UtilitiesTest {
    @Test func hashingFunction() {
        let testImage = TestResourceManager.shared.testImage
        let hashForTestImage = TestResourceManager.shared.hashForTestImage
        
        #expect(throws: Never.self) {
            let calculatedSha256 = try FileManager.getSHA256(forFile: testImage)
            
            #expect(hashForTestImage == calculatedSha256.hexString)
            
            let dataFromSha256 = Data(calculatedSha256)
            
            #expect(dataFromSha256 == TestResourceManager.shared.hashAsDataForTestImage)
        }
    }
}
