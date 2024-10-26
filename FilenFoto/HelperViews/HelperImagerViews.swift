//
//  HelperImagerViews.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI
import PhotosUI
import AVKit

struct ViewManager: View {
    @EnvironmentObject var photoEnviorment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
        
    let onSwipeUp: (() -> Void)
    let onSwipeDown: (() -> Void)
        
    init(onSwipeUp: @escaping () -> Void = {}, onSwipeDown: @escaping () -> Void = {}) {
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
    }
    
    var body: some View {
        return (
            fullImageState.imageViewGeneration.generateView(
                dbPhotoAsset: photoEnviorment.selectedDbPhotoAsset,
                scale: $fullImageState.scale,
                offset: $fullImageState.offset,
                scrolling: $fullImageState.scrolling,
                onSwipeUp: onSwipeUp,
                onSwipeDown: onSwipeDown
            )
//            fullImageState.view ?? AnyView(ZoomablePhoto(
//            scale: $fullImageState.scale,
//            offset: $fullImageState.offset,
//            onSwipeUp: onSwipeUp,
//            onSwipeDown: onSwipeDown,
//            image: .constant(uiImage ?? (imgPath != nil ? (UIImage(contentsOfFile: imgPath!) ?? UIImage()) : UIImage())))
                                     //            .aspectRatio(contentMode: .fit)
                                     //            .scaledToFit()
                .overlay {
                    if !fullImageState.imageViewGeneration.isLoaded(dbPhotoAsset: photoEnviorment.selectedDbPhotoAsset) {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                ProgressView().progressViewStyle(.circular)
                                    .scaleEffect(1.5)
                            )
                            .allowsHitTesting(false)
                    }
                })
//            }))
//        .scaleEffect(fullImageState.adjustedScale)
//        .offset(fullImageState.offset)
        .clipShape(Rectangle())
//        .onChange(of: fullImageState.isScrolling) {
//            if !fullImageState.isScrolling && photoEnviorment.selectedDbPhotoAsset != nil {
//                fullImageState.isScrolling = true
//                self.view = nil
//                self.assetFileUrl = nil
//                curTask?.cancel()
//                curTask = Task {
//                    await getView()
//                }
//            }
//        }
//        .onAppear {
//            if !fullImageState.isScrolling {
//                fullImageState.isScrolling = true
//                self.view = nil
//                self.assetFileUrl = nil
//                curTask?.cancel()
//                curTask = Task {
//                    await getView()
//                }
//            }
//        }
//        .onChange(of: photoEnviorment.selectedDbPhotoAsset) {
//            self.view = nil
//            self.fullImageState.assetFileUrl = nil
//            if fullImageState.hasUserStoppedScrolling {
//                curTask?.cancel()
//                curTask = Task {
//                    await getView()
//                }
//            }
//        }
    }
}

struct UIKitLivePhotoView: UIViewRepresentable {
    let livephoto: PHLivePhoto?
    
    func makeUIView(context: Context) -> PHLivePhotoView {
        return PHLivePhotoView()
    }
    
    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livephoto
    }
}

struct ThumbnailView: View {
    //    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    let thumbnailName: String
    
    var body: some View {
        //#if targetEnvironment(simulator)
        //        if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"], isPrev == "1" {
        ////            print("Building \(dbPhotoAsset.localIdentifier)")
        //            let randomColors = [
        //                UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.orange,
        //                UIColor.purple, UIColor.cyan, UIColor.magenta,
        //            ]
        //            uiImage = dbPhotoAsset.localIdentifier.image(withAttributes: [
        //                .foregroundColor: UIColor.red,
        //                .font: UIFont.systemFont(ofSize: 10.0),
        //                .backgroundColor: randomColors.randomElement()!,
        //            ])
        //        } else {
        ////            print("building \(dbPhotoAsset.localIdentifier)")
        //        }
        //#endif
        
        //        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
        //            .resizable()
        //            .scaledToFill()
        //        )
        //        return Color.clear.background(Image(uiImage: (uiImage ?? UIImage()))
        ////        return Color.clear.background(AsyncImage(url: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName))
        //            .resizable()
        //                    .scaledToFill()
        //                )
        return Image(uiImage: (UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: thumbnailName).path) ?? UIImage()))
        //        return Color.clear.background(AsyncImage(url: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: dbPhotoAsset.thumbnailFileName))
            .resizable()
            .scaledToFill()
            .aspectRatio(1, contentMode: .fit)
            .clipped()
    }
}
