//
//  HelperImagerViews.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI
import PhotosUI
import AVKit

struct FilenAsyncImage: View {
    @EnvironmentObject var photoEnviorment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    var dbAsset: DBPhotoAsset?
    
    let onSwipeUp: (() -> Void)
    let onSwipeDown: (() -> Void)
    
    init(dbAsset: DBPhotoAsset?, onSwipeUp: @escaping () -> Void = {}, onSwipeDown: @escaping () -> Void = {}) {
        self.dbAsset = dbAsset
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
    }
    
    func getClipShape() -> any Shape {
        dbAsset?.mediaSubtype.contains(.photoScreenshot) ?? false ? RoundedRectangle(cornerSize: .init(width: 20, height: 20)) : Rectangle()
    }
    
    var body: some View {
        return (
            fullImageState.imageViewGeneration.generateView(
                dbPhotoAsset: dbAsset,
                scale: $fullImageState.scale,
                offset: $fullImageState.offset,
                scrolling: $fullImageState.scrolling,
                onSwipeUp: onSwipeUp,
                onSwipeDown: onSwipeDown
            )
            .overlay {
                if !fullImageState.imageViewGeneration.isLoaded(dbPhotoAsset: dbAsset) {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView().progressViewStyle(.circular)
                                .scaleEffect(1.5)
                        )
                        .allowsHitTesting(false)
                }
            })
    }
}
