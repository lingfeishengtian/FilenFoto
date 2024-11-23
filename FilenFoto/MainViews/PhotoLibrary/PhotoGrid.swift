//
//  PhotoGrid.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SwiftUI

var shouldAppear: [Int] = []

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
    @inline(__always) private func matchedGeometryHide(_ dbPhotoAsset: DBPhotoAsset) -> Bool {
        photoEnvironment.selectedDbPhotoAsset?.id == dbPhotoAsset.id && photoEnvironment.shouldShowFullImageView
    }
    
    @State private var savedUUIDForFullImageTransition: UUID?
    
    var body: some View {
        LazyVGrid(
            columns: [
                .init(.adaptive(minimum: 100 + scalingAdjust, maximum: .infinity), spacing: 3)
            ], spacing: 3
        ) {
            ForEach(
                LazyDBAssetArray(endIndex: photoEnvironment.countOfPhotos)
            ) { lazyDbPhotoAsset in
                let dbPhotoAsset = lazyDbPhotoAsset.dbPhotoAsset
                if matchedGeometryHide(dbPhotoAsset) {
                    Color.clear
                } else {
                    Image(uiImage: UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) ?? UIImage())
                    .resizable()
                    .matchedGeometryEffect(
                        id: "thumbnailImageTransition"
                        + String(dbPhotoAsset.id),
                        in: animation
                    )
                    .transition(.blurReplace)
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .aspectRatio(1, contentMode: .fit)
                    .contentShape(Rectangle())
                    .overlay (alignment: .topLeading) {
                        if dbPhotoAsset.isBurst {
                            Image(systemName: "laser.burst")
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            photoEnvironment.setCurrentSelectedDbPhotoAsset(dbPhotoAsset, index: PhotoDatabase.shared.index(of: dbPhotoAsset))
                            keyboardFocus = false
                        }
                    }
                }
            }
            /// The index code from the database is so efficient versus ID generation from SwiftUI, it's laggier to compare IDs from previous ForEach loops rather than just making a new one every single refresh
            /// .id(lazyDBAssetArray.id) would actually be slower since SwiftUI has to make O(n) comparisons when n views are loaded in
        }.id(UUID())
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
