//
//  FilenFotoError.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import Foundation
import SwiftUI

enum FilenFotoError: LocalizedError {
    case coreDataContext
    case invalidFile
    case invalidImage
    case invalidVideo
    case invalidAudio
    case missingResources
    
    case noCameraPermissions
    case cameraPermissionDenied
    
    case filenClientUnavailable
    case filenRootFolderDirectoryUnavailable
    
    case remoteResourceStillExistsInFilen
    case remoteResourceNotFoundInFilen
    
    case internalError(String)
    case appBundleBroken
    
    var errorDescription: LocalizedStringResource? {
        switch self {
        case .coreDataContext:
            return "Core data error"
        case .invalidFile:
            return "Tried to access an invalid file."
        case .missingResources:
            return "Asset is in an invalid state."
        case .noCameraPermissions:
            return "Please allow camera access."
        case .cameraPermissionDenied:
            return "Camera access was denied, you can re-enable it in settings."
        case .filenClientUnavailable, .filenRootFolderDirectoryUnavailable:
            return "Internal filen client state error."
        case .remoteResourceStillExistsInFilen:
            return "Tried to delete a resource that was not deleted from Filen"
        case .remoteResourceNotFoundInFilen:
            return "Tried to download a resource that was never uploaded to Filen"
        case .internalError(let englishInternalError):
            return "An internal error occurred: \(englishInternalError)"
        case .appBundleBroken:
            return "The app was modified in a way that this app cannot recover from. Please reinstall the app."
        case .invalidImage:
            return "File could not be parsed as image."
        case .invalidVideo:
            return "File could not be parsed as video."
        case .invalidAudio:
            return "File could not be parsed as audio."
        }
    }
}
