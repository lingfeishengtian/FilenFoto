//
//  PagedImageView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/23/24.
//

import SwiftUI
import SwiftUIPager

struct PagedImageView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    
    let animation: Namespace.ID
    
    @State private var page: Page = .first()
    
    func swipeDownOnImage () {
        if fullImageState.showDetail || fullImageState.offset.height < 0 {
            DispatchQueue.main.async {
                withAnimation {
                    fullImageState.showDetail = false
                }
            }
        } else {
            fullImageState.offset.height = fullImageState.dismissThreshold
            DispatchQueue.main.async {
                withAnimation(.snappy) {
                    photoEnvironment.shouldShowFullImageView = false
                }
            }
        }
    }
    
    func swipeUpOnImage () {
        DispatchQueue.main.async {
            withAnimation {
                fullImageState.showDetail = true
//                if fullImageState.offset.height > -200 && fullImageState.offset.height < 0 {
//                    withAnimation {
//                        fullImageState.offset.height = -200
//                    }
//                }
            }
        }
    }
    
    @State private var location: CGPoint = .zero
    
    var body: some View {
        let _ = print(fullImageState.scale)
        GeometryReader { reader in
            Pager(page: self.page, data: photoEnvironment.lazyArray.sortedArray, id: \.self) { dbAsset in
                
                if dbAsset == photoEnvironment.selectedDbPhotoAsset {
                    ViewManager(onSwipeUp: swipeUpOnImage, onSwipeDown: swipeDownOnImage)
                    .matchedGeometryEffect(
                        id: "thumbnailImageTransition"
                        + dbAsset.localIdentifier, in: animation)
                    .frame(width: reader.size.width, height: reader.size.height)
//                    .onChange(of: fullImageState.offset) {
//                        if fullImageState.offset.height < -10 {
//                            withAnimation {
//                                fullImageState.showDetail = true
////                                fullImageState.sheetOffset = .zero
//                            }
//                        } else if fullImageState.offset.height > 10 && !fullImageState.showDetail {
//                            withAnimation {
//                                fullImageState.showDetail = false
////                                fullImageState.sheetOffset = .zero
//                            }
//                        }
//                    }
//                    .position(location)
//                    .gesture(DragGesture().onChanged({ value in
//                        location = value.location
//                    }))
                } else {
                    ZoomablePhoto(
                        scale: $fullImageState.scale,
                        offset: $fullImageState.offset,
                        scrolling: $fullImageState.scrolling,
                        onSwipeUp: swipeUpOnImage,
                        onSwipeDown: swipeDownOnImage,
                        image: .constant(UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage()))
                    .frame(width: reader.size.width, height: reader.size.height)
//                    .offset(showDetail ? .init(width: 0, height: sheetOffset.height) : .zero)
                }
            }
            .onPageChanged({ (newIndex) in
                photoEnvironment.selectedDbPhotoAsset = photoEnvironment.lazyArray.sortedArray[newIndex]
                Task {
                    await fullImageState.getView(selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset!)
                }
            })
            .interactive(scale: 0.8)
//            .allowsDragging(!fullImageState.showDetail && fullImageState.scale == 1.0)
            .allowsDragging(!fullImageState.shouldHideBars)
        }
        .onAppear {
            if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
                self.page.update(.new(index: photoEnvironment.lazyArray.binSearch(selectedDbPhotoAsset)))
            }
            //            isScrolling = false
        }
        .onChange(of: photoEnvironment.selectedDbPhotoAsset) {
            if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
                self.page.update(.new(index: photoEnvironment.lazyArray.binSearch(selectedDbPhotoAsset)))
            }
            //            isScrolling = false
        }
    }
}
