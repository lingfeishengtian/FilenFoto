//
//  BurstPageView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/27/24.
//

import SwiftUI
import SwiftUIPager

struct BurstPageView : View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    
    let matchedAnimationLocalIdentifier: String
    let animation: Namespace.ID
    let dbPhotoAssets: [DBPhotoAsset]
    @State var page: Page = .first()
    
    var selectedLocalIdentifier: String {
        dbPhotoAssets[page.index].localIdentifier
    }
    
    var body: some View {
            GeometryReader { reader in
                Pager(page: page, data: dbPhotoAssets, id: \.self) { dbPhotoAsset in
                    FilenAsyncImage(dbAsset: dbPhotoAsset)
//                    .matchedGeometryEffect(
//                            id: (selectedLocalIdentifier == dbPhotoAsset.localIdentifier ? ("thumbnailImageTransition" + matchedAnimationLocalIdentifier) : dbPhotoAsset.localIdentifier), in: animation)
                    .frame(width: reader.size.width, height: reader.size.height)
                }
                .onPageChanged({ (newIndex) in
                    let selectedDbPhotoAsset = dbPhotoAssets[newIndex]
                    Task {
                        await fullImageState.getView(selectedDbPhotoAsset: selectedDbPhotoAsset)
                    }
                })
                .interactive(scale: 0.8)
                .allowsDragging(!fullImageState.shouldHideBars)
                .onAppear {
//                    var bestPhoto = 0
//                    for (ind, dbPhotoAsset) in dbPhotoAssets.enumerated() {
//                        if dbPhotoAsset.burstSelectionTypes.contains(.userPick) {
//                            bestPhoto = ind
//                            break
//                        } else if dbPhotoAsset.burstSelectionTypes.contains(.autoPick) {
//                            bestPhoto = ind
//                        }
//                    }
                    
                    let bestPhoto = dbPhotoAssets.firstIndex(of: photoEnvironment.selectedDbPhotoAsset!)?.int ?? 0
                    page.update(.new(index: bestPhoto))
                    
//                    Task {
//                        await fullImageState.getView(selectedDbPhotoAsset: dbPhotoAssets[bestPhoto])
//                    }
                }
            }
    }
}
