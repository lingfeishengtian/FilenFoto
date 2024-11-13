//
//  PhotoGrid.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SwiftUI

var shouldAppear: [Int: Bool] = [:]

struct LazyPhotoGrid : View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @FocusState.Binding var keyboardFocus: Bool
    let animation: Namespace.ID
    
    @State private var scalingAdjust: CGFloat = 0
    
    private func asyncUrlImageViewGenerator(thumbnailURL: URL, cancelledErrorView: some View = Color.red) -> some View {
        AsyncImage(url: thumbnailURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if phase.error != nil {
                if phase.error!.localizedDescription == "cancelled" {
                    cancelledErrorView
                } else {
                    Color.red
                }
            } else {
                ProgressView()
            }
        }
    }
    
    /// Always inline due to the way SwiftUI creates these views
    @inline(__always) private func imageOpacity(_ dbPhotoAsset: DBPhotoAsset) -> Bool {
        photoEnvironment.selectedDbPhotoAsset == dbPhotoAsset && photoEnvironment.shouldShowFullImageView == true
    }
    
    var body: some View {
        LazyVGrid(
            columns: [
                .init(.adaptive(minimum: 100 + scalingAdjust, maximum: .infinity), spacing: 3)
            ], spacing: 3
        ) {
            ForEach(
                0..<PhotoDatabase.shared.getCountOfPhotos(),
                id: \.self
            ) { index in
                let dbPhotoAsset = PhotoDatabase.shared.getDBPhotoSync(
                    atOffset: index
                )!
                    Color.clear.background(
                        Image(
                            uiImage: UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) ?? UIImage()
                        )
                        .resizable()
                        .matchedGeometryEffect(
                            id: "thumbnailImageTransition"
                            + dbPhotoAsset.localIdentifier,
                            in: animation,
                            isSource: true
                        )
                        .scaledToFill()
                        .clipped()
                    )
                    .contentShape(Rectangle())
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
                    .overlay (alignment: .topLeading) {
                        if dbPhotoAsset.isBurst {
                            Image(systemName: "laser.burst")
                        }
                    }
                    .opacity(imageOpacity(dbPhotoAsset) ? 0 : 1)
                    .onTapGesture {
                        withAnimation {
                            photoEnvironment.setCurrentSelectedDbPhotoAsset(dbPhotoAsset, index: index)
                            keyboardFocus = false
                        }
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(MagnificationGesture()
            .onEnded { value in
                print(value.magnitude)
                if (value.magnitude > 3.0) {
                    withAnimation {
                        scalingAdjust = 0
                    }
                } else if (value.magnitude < 0.5) {
                    withAnimation {
                        scalingAdjust = -20
                    }
                }
            })
    }
}
