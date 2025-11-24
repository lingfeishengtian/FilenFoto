//
//  PhotoDetailsViewProvider.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/15/25.
//

import Foundation
import SwiftUI

class PhotoViewProvider: SwiftUIViewFactoryProtocol {
    func topBar(assetValueBridge image: ValueBridge<WorkingSetFotoAsset>) -> any View {
        PhotoDetailsTopBarView(workingSetFotoAsset: image)
    }

    func bottomBar(assetValueBridge: ValueBridge<WorkingSetFotoAsset>) -> any View {
        Button("Test Filen") {
        }
    }

    func detailedView(assetValueBridge: ValueBridge<WorkingSetFotoAsset>) -> any View {
        VStack {
            Text("Photo Detail View")
                .font(.headline)
                .padding()
        }
    }

    var noImagesAvailableView: any View {
        VStack {
            Image(systemName: "photo.trianglebadge.exclamationmark")
                .font(.title)
                .padding()
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.breathe)
            Text("Your library is empty")
                .bold()
        }
    }
}
