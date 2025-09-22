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
}

enum ProviderState: Int16 {
    case notStarted = 0
    case failed = 1
    case succeded = 2
}
