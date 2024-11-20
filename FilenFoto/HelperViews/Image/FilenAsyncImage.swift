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
    
    init(dbAsset: DBPhotoAsset?) {
        self.dbAsset = dbAsset
    }
    
    func getClipShape() -> any Shape {
        dbAsset?.mediaSubtype.contains(.photoScreenshot) ?? false ? RoundedRectangle(cornerSize: .init(width: 20, height: 20)) : Rectangle()
    }
    
    var body: some View {
//        if let dbAsset, let img = fullImageState.imageViewGeneration.getImageURL(for: dbAsset) {
//            ZoomableImage(onSwipeUp: onSwipeUp, onSwipeDown: onSwipeDown, imageURL: img)
//        } else {
            fullImageState.imageViewGeneration.generateView(
                dbPhotoAsset: dbAsset,
                isPinching: $fullImageState.isPinching
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
            }
        }
//    }
}
