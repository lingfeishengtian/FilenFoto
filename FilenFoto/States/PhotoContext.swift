//
//  PhotoContext.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import Foundation
import UIKit
import os

class PhotoContext: ObservableObject {
    static let shared = PhotoContext()
    private init() {}
    private static let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "PhotoContext")
    
    @Published var filenClient: FilenClient? = {
        guard let authData = FFDefaults.shared.filenAuthData else {
            return nil
        }

        do {
            return try clientFromCredentials(clientCredentials: authData)
        } catch {
            logger.warning("Failed to create FilenClient from stored credentials: \(error.localizedDescription)")
            return nil
        }
    }() {
        didSet {
            if let client = filenClient {
                FFDefaults.shared.filenAuthData = client.exportCredentials()
            }
        }
    }
    
    @Published var rootPhotoDirectory: UUID? = {
        guard let rootUUIDString = FFDefaults.shared.rootFolderUUID else { return nil }
        
        return UUID(uuidString: rootUUIDString)
    }() {
        didSet {
            if let directory = rootPhotoDirectory {
                FFDefaults.shared.rootFolderUUID = directory.uuidString
            }
        }
    }
    
    @Published var errorMessages: [String] = []
    
    func report(error: FilenClientError) {
        self.report(error.errorDescription ?? "Unknown error")
    }
    
    func report(_ errorString: String) {
        DispatchQueue.main.async {
            self.errorMessages.append(errorString)
        }
    }
}
