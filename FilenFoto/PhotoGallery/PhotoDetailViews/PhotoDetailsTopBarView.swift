//
//  PhotoDetailsTopBarView.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/15/25.
//

import SwiftUI

struct PhotoDetailsTopBarView: View {
    @ObservedObject var workingSetFotoAsset: ValueBridge<WorkingSetFotoAsset>
    
    var asset: ReadOnlyNSManagedObject<FotoAsset> {
        workingSetFotoAsset.value.asset
    }
    
    var body: some View {
        Button {
            
        } label: {
            Text(asset.placemark?.name ?? "")
                .fontWeight(.bold)
        }
        .padding()
        .buttonStyle(.glass)
    }
}

#Preview {
    PhotoDetailsTopBarView(
        workingSetFotoAsset: ValueBridge(FFMockDataGenerator.generateWorkingSetFotoAsset())
    )
}
