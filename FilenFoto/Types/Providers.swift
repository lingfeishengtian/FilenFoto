//
//  ProviderStatus.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/20/25.
//

import Foundation

enum AvailableProvider: Int16, CaseIterable, RawRepresentable {
    case thumbnailProvider = 1

    var provider: PhotoActionProviderDelegate {
        switch self {
        case .thumbnailProvider:
            return ThumbnailProvider.shared
        }
    }
    
    var name: LocalizedStringResource {
        switch self {
        case .thumbnailProvider:
            return "Thumbnail Provider"
        }
    }
    
    var progressWeight: Int64 {
        switch self {
        case .thumbnailProvider:
            return 10
        }
    }
    
    static var totalProgressWeight = {
        let totalProgressWeight = allCases.reduce(0) { accumulatedResult, provider in
            accumulatedResult + provider.progressWeight
        }
        
        return totalProgressWeight
    }()
    
#if DEBUG
    static func progressWeightsDebugString() -> String {
        var finalMessage = ""
        
        for provider in allCases {
            finalMessage += "\(provider.name): \(provider.progressWeight)\n"
        }
        
        return finalMessage
    }
#endif // DEBUG

}

enum ProviderState: Int16 {
    case notStarted = 0
    case failed = 1
    case succeded = 2
}
