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
            VStack {
                if let placename = asset.placemark?.name {
                    Text(placename)
                        .fontWeight(.bold)
                        .font(.subheadline)
                }
                
                if let dateCreated = asset.dateCreated {
                    Text(dateCreated.formatted(date: .abbreviated, time: .shortened))
                        .fontWeight(.medium)
                        .font(.caption)
                }
            }
            .padding(4)
        }
        .buttonStyle(.glass)
        .tint(.primary.opacity(0.9))
        .padding(.top, 4)
    }
}

#Preview {
    PhotoDetailsTopBarView(
        workingSetFotoAsset: ValueBridge(FFMockDataGenerator.generateWorkingSetFotoAsset())
    )
}
