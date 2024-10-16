//
//  FilenCredentialStorage.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import Foundation
import FilenSDK

struct SDKPersistence : Decodable, Encodable {
    let masterKeys: [String]
    let apiKey: String
}

func isLoggedIn() -> Bool {
    return getFilenClientWithUserDefaultConfig() != nil
}

func getFilenClientWithUserDefaultConfig() -> FilenClient? {
    guard let masterKeys = UserDefaults.standard.array(forKey: "sdkConfig.masterKeys") as? [String], let apiKey = UserDefaults.standard.string(forKey: "sdkConfig.apiKey") else {
        return nil
    }
    
    return FilenClient(tempPath: FileManager.default.temporaryDirectory, from: SDKConfiguration(masterKeys: masterKeys, apiKey: apiKey))
}

func saveUserDefaultConfig(client: FilenClient) {
    guard let sdkConfig = client.config else {
        return
    }
    
    UserDefaults.standard.setValue(sdkConfig.masterKeys, forKey: "sdkConfig.masterKeys")
    UserDefaults.standard.setValue(sdkConfig.apiKey, forKey: "sdkConfig.apiKey")
}
