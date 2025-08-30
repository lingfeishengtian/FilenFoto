//
//  SwiftUIProviderProtocolTest.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import SwiftUI
@testable import FilenFoto

/// Just testing the typing
struct SwiftUIProviderProtocolTest: SwiftUIProviderProtocol {
    func view(for providerRoute: FilenFoto.SwiftUIProviderRoute) -> any View {
        switch providerRoute {
        case .topBar:
            Text("Hello, World!")
        case .bottomBar:
            Button("Test") {
                print("clicked")
            }
        case .detailedImage:
            VStack {
                Text("Hello, World!")
            }
        }
    }
}
