//
//  SwiftUIProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import SwiftUI

protocol SwiftUIProviderProtocol {
    func view(for providerRoute: SwiftUIProviderRoute, with image: UIImage) -> any View
}
